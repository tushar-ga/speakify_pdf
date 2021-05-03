import json
import boto3
from operator import itemgetter
import fitz
import re
from io import BytesIO
# import extractHeader
# from extractHeaders import GetBlockNumber,GetElementsFromTOC,fonts,font_tags,headers_para

def lambda_handler(event, context):

	s3 = boto3.resource('s3')

	book = event['queryStringParameters']['book']

	document = s3.Bucket("mypdffile").Object(book+'.pdf').get()['Body'].read()
	doc = fitz.open(stream=document, filetype="pdf")

	primary_toc = GetElementsFromTOC(doc)

	font_counts, styles = fonts(doc, granularity=False)
	size_tag = font_tags(font_counts, styles)
	elements = headers_para(doc, size_tag)

	sdoc = book+"_secondary"
	pdoc = book+"_primary"

	with open("/tmp/"+sdoc+".json", 'w', encoding='utf-8') as json_out:
		json.dump(elements, json_out, ensure_ascii = False)
		json_out.close()
	
	s3.Bucket("pdfheaders").upload_file("/tmp/"+sdoc+".json", sdoc+'.json') 
		
# 	with open("/tmp/"+sdoc+".json", 'r', encoding='utf-8') as json_out:
#         print(json_out)

	if len(primary_toc) > 0:
		with open("/tmp/"+pdoc+".json", 'w', encoding='utf-8') as json_out:
			json.dump(primary_toc, json_out, ensure_ascii = False)
			json_out.close()
		s3.Bucket("pdfheaders").upload_file("/tmp/"+pdoc+".json", pdoc+'.json')   	
    
	return {
		'statusCode': 200,
		'body': json.dumps('Headers extracted from '+book)
	}


def GetBlockNumber(page, title):
    blocks = page.getText("dict")["blocks"]
    rectangle = page.search_for(title) #first Rectangle
    if len(rectangle) > 0:
        rectangle = rectangle[0]
    else:
        return 0
    for b in blocks:
        box = b['bbox']
        if(box[0] == rectangle[0] and box[1] == rectangle[1] and box[2] == rectangle[2] and box[3] == rectangle[3] ):
            return b['number']
    return 0

def GetElementsFromTOC(doc):
    toc = doc.get_toc()
    if(len(toc)==0):
        return []
    headers = []
    for head in toc:
        lvl = head[0]
        title = head[1]
        page = head[2] - 1 #0 based indexing of pages
        blockNumber = GetBlockNumber(doc[page],title)
        head = '<h'+str(lvl)+'>'+str(title)+'{'+str(page)+'-'+str(blockNumber)+'}'
        headers.append(head)
    return headers
        
def fonts(doc, granularity=False):
    """Extracts fonts and their usage in PDF documents.
    :param doc: PDF document to iterate through
    :type doc: <class 'fitz.fitz.Document'>
    :param granularity: also use 'font', 'flags' and 'color' to discriminate text
    :type granularity: bool
    :rtype: [(font_size, count), (font_size, count}], dict
    :return: most used fonts sorted by count, font style information
    """
    styles = {}
    font_counts = {}

    for page in doc:
        blocks = page.getText("dict")["blocks"]
        for b in blocks:  # iterate through the text blocks
            if b['type'] == 0:  # block contains text
                for l in b["lines"]:  # iterate through the text lines
                    for s in l["spans"]:  # iterate through the text spans
                        if granularity:
                            identifier = "{0}_{1}_{2}_{3}".format(s['size'], s['flags'], s['font'], s['color'])
                            styles[identifier] = {'size': s['size'], 'flags': s['flags'], 'font': s['font'],
                                                  'color': s['color']}
                        else:
                            identifier = "{0}".format(s['size'])
                            styles[identifier] = {'size': s['size'], 'font': s['font']}

                        font_counts[identifier] = font_counts.get(identifier, 0) + 1  # count the fonts usage

    font_counts = sorted(font_counts.items(), key=itemgetter(1), reverse=True)

    if len(font_counts) < 1:
        raise ValueError("Zero discriminating fonts found!")

    return font_counts, styles


def font_tags(font_counts, styles):
    """Returns dictionary with font sizes as keys and tags as value.
    :param font_counts: (font_size, count) for all fonts occuring in document
    :type font_counts: list
    :param styles: all styles found in the document
    :type styles: dict
    :rtype: dict
    :return: all element tags based on font-sizes
    """
    p_style = styles[font_counts[0][0]]  # get style for most used font by count (paragraph)
    p_size = p_style['size']  # get the paragraph's size

    # sorting the font sizes high to low, so that we can append the right integer to each tag
    font_sizes = []
    for (font_size, count) in font_counts:
        font_sizes.append(float(font_size))
    font_sizes.sort(reverse=True)

    # aggregating the tags for each font size
    idx = 0
    size_tag = {}
    for size in font_sizes:
        idx += 1
        if size == p_size:
            idx = 0
            size_tag[size] = '<p>'
        if size > p_size:
            size_tag[size] = '<h{0}>'.format(idx)
        elif size < p_size:
            size_tag[size] = '<s{0}>'.format(idx)

    return size_tag


def headers_para(doc, size_tag):
    """Scrapes headers & paragraphs from PDF and return texts with element tags.
    :param doc: PDF document to iterate through
    :type doc: <class 'fitz.fitz.Document'>
    :param size_tag: textual element tags for each size
    :type size_tag: dict
    :rtype: list
    :return: texts with pre-prended element tags
    """
    header_para = []  # list with headers and paragraphs
    first = True  # boolean operator for first header
    previous_s = {}  # previous span

    stack = []
    pageMap = {}

    for pageIdx,page in enumerate(doc):
        blocks = page.getText("dict")["blocks"]
        
        for b in blocks:  # iterate through the text blocks
            if b['type'] == 0:  # this block contains text

                # REMEMBER: multiple fonts and sizes are possible IN one block

                block_string = ""  # text found in block
                for l in b["lines"]:  # iterate through the text lines
                    for s in l["spans"]:  # iterate through the text spans
                        if s['text'].strip():  # removing whitespaces:
                            if first:
                                previous_s = s
                                first = False
                                block_string = size_tag[s['size']] + s['text']
                            else:
                                if s['size'] == previous_s['size']:

                                    if block_string and all((c == "|") for c in block_string):
                                        # block_string only contains pipes
                                        block_string = size_tag[s['size']] + s['text']
                                    if block_string == "":
                                        # new block has started, so append size tag
                                        block_string = size_tag[s['size']] + s['text']
                                    else:  # in the same block, so concatenate strings
                                         block_string += " " + s['text']

                                else:
                                    if block_string.startswith('<h'):
                                        PERMITTED_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-<>. " 
                                        block_string = "".join(c for c in block_string if c in PERMITTED_CHARS)
                                        if  not block_string.endswith(">") and not block_string.endswith("> "):
                                            block_string += "{"+ str(pageIdx)+'-'+str(b['number'])+"}"
                                            header_para.append(block_string)
                                    block_string = size_tag[s['size']] + s['text']

                                previous_s = s

                    # new block started, indicating with a pipe
                    block_string += "|"
                if block_string.startswith('<h'):
                    PERMITTED_CHARS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-<>. " 
                    block_string = "".join(c for c in block_string if c in PERMITTED_CHARS)
                    block_string += "{"+ str(pageIdx)+'-'+str(b['number'])+"}"
                    if not block_string.endswith(">") and not block_string.endswith("> ") :
                        header_para.append(block_string)

    return header_para
