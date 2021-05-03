import json
import boto3

def lambda_handler(event, context):
    
    dynamodb = boto3.resource('dynamodb')

    table = dynamodb.Table('users')

    table_iterator = table.scan()['Items']
    
    users_list = []
    
    for row in table_iterator:
        users_list.append(row['email'])
    
    return {
        'statusCode': 200,
        'body': json.dumps(users_list)
    }
