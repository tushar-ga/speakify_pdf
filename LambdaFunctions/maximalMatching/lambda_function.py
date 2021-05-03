import json
import boto3

import stopwords

import pickle

def lambda_handler(event, context):
   
    book = event['queryStringParameters']['book']
    query = event['queryStringParameters']['query']
    s3 = boto3.resource('s3')
    wordMap = pickle.loads(s3.Bucket("pdftags").Object(book+".pickle").get()['Body'].read())
   
   
    # with BytesIO() as data:
    #     s3.Bucket("pdftags").download_fileobj(book+".pkl", data)
    #     data.seek(0)    # move back to the beginning after writing
    #     wordMap = pickle.load(data)
        
    
    keywords = query.split()
    match = {}
    for keyword in keywords:
        keyword = keyword.lower()
        if(keyword in stopwords.stopwords().words):
            continue
        for head in wordMap:
            wordMap[head].text = wordMap[head].text.lower()
            headWords= wordMap[head].text.split()
            if(keyword in wordMap[head].text):
                match[head] = match.get(head, 0)+1
                
    sort_match = sorted(match.items(), key = lambda x: wordMap[x[0]].fontSize,reverse=True)
    sort_match = sorted(sort_match, key = lambda x:x[1], reverse=True)
    
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps(sort_match)
    }
    
    # return sort_match
