import json
from pprint import pprint
import boto3

def lambda_handler(event, context):

    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('users')
    
    response = table.get_item(
        Key={
            'email': event['email']
        }
    )

    if response.get('Item',None) != None:
        return {
            'statusCode': 200,
            'body': json.dumps('User already exists')
        }
    else:
        # create user
        response = table.put_item(
           Item={
                'email': event['email'],
                'books': event['books'],
                'other': event['other']
            }
        )
    
        return {
            'statusCode': 200,
            'body': json.dumps('User created with email : '+event['email'])
        }
