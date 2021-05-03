import json
from googletrans import Translator

def lambda_handler(event, context):
    text_in = event['queryStringParameters']['text']
    # text_in = event['text']
    translator = Translator()
    result = translator.translate(text_in, src='en', dest='hi')
    return {
        'statusCode': 200,
        'body': json.dumps(result.text, ensure_ascii=False).encode('utf8')
    }