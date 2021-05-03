import json
import boto3
import pickle

from tag import Tag

def lambda_handler(event, context):
    
    book = event['queryStringParameters']['book']
    heading = event['queryStringParameters']['heading']
    
    s3 = boto3.resource('s3')
    wordMap = pickle.loads(s3.Bucket("pdftags").Object(book+".pickle").get()['Body'].read())

    # print('check ',heading,type(wordMap))
    tag = wordMap.get(heading,None)
    
    # print(tag.text)
    
    page_range = (tag.start_page,tag.end_page)
    
    return {
        'statusCode': 200,
        'body': json.dumps(page_range)
    }
