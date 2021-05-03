import boto3
import json
import pickle
from tag import Tag

def lambda_handler(event, context):
    
    s3 = boto3.resource('s3')
    book = event['queryStringParameters']['book']
    
    tag_type = 'secondary'
    
    book_headers = None
    
    if tag_type=='primary':
        book_headers = book+'_primary.json'
    else:
        book_headers = book+'_secondary.json'
    
    print(book_headers)
    
    data = json.loads(s3.Bucket("pdfheaders").Object(book_headers).get()['Body'].read())
    # json_data = json_data.decode('utf8')
    
    print('type',type(data))
    
    wordMap = {}

    stack = []

    for header in data:
    
        fontS = header.find("h")
        headS = header.find(">")
        posS = header.find("{")
        posE = header.find("}")
        blockS = posS+header[posS:].find("-")
        heading = header[headS+1:posS]
    
        fontSize = int(header[fontS+1:headS])
        text = header[headS+1:posS]
        start_page = int(header[posS+1:blockS])
        start_block = int(header[blockS+1:posE])
        text = text.strip()
        heading = heading.strip()
        if(len(text)==0):
            continue
        tag = Tag(text,fontSize,start_page,start_block,0,0) 

    
        if stack:
            # Remove paragraphs from stack with headers having lesser font
            while stack and stack[-1].fontSize>=fontSize:
                # print('Popping',stack[-1].text)
                rm_tag = stack.pop()
                rm_tag.end_page = start_page
                rm_tag.end_block = start_block-1 # is -1 when heading on new page
            
            if stack:
                if heading not in wordMap.keys():
                    wordMap[heading] = tag
                else:
                    tag.text = stack[-1].text+' '+heading
                    wordMap[stack[-1].text+' '+heading] = tag
                stack[-1].child.append(tag)
                # print(tag.text,' child of ',stack[-1].text)

        stack.append(tag)
        
    # put wordMap into s3 bucket 'pdftags'
    with open("/tmp/"+book+".pickle", 'wb') as out:
        pickle.dump(wordMap, out, protocol=pickle.HIGHEST_PROTOCOL)
        out.close()
    s3.Bucket("pdftags").upload_file("/tmp/"+book+".pickle", book+'.pickle')

    return {
        'statusCode': 200,
        'body': json.dumps(tag_type+' tags generated for '+book)
    }
