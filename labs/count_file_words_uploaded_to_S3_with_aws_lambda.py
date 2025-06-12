import boto3, os

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    sns = boto3.client('sns')

    # Get the bucket and object key from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    # Read file contents from S3
    content = s3.get_object(Bucket=bucket, Key=key)['Body'].read().decode('utf-8')
    word_count = len(content.split())
   
    # Publish the word count message to SNS
    topic_arn = os.environ['TOPIC_ARN']
    sns.publish(TopicArn=topic_arn, Subject='Word Count Result',
                Message=f"The file {key} contains {word_count} words.")
    return {'statusCode': 200}
