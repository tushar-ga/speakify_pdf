import json
import boto3

def lambda_handler(event, context):
    
    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('users')
    
    response = table.delete_item(
        Key={
            'email' : event['email']
        }
    )
    
    return response
