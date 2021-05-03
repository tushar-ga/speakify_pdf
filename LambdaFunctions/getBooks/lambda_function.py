import json
import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    
    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('users')
    
    email = event['queryStringParameters']['email']
    
    try:
        response = table.get_item(Key={'email': email})
    except ClientError as e:
        print(e.response['Error']['User Not Found'])
    else:
        return response['Item']['books']
