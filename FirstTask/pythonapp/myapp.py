import boto3
from flask import Flask

s3 = boto3.client('s3')
app = Flask(__name__)

@app.route('/')
def index(event, lambda_context):
    s3_bucket_name = 'fbgbl'
    s3_file = 'FileFromS3.txt'

    response = s3.get_object(Bucket=s3_bucket_name, Key=s3_file)
    file_content = response['Body'].read().decode('utf-8')

    return f"<h1>My the force be with you.</h1><p>{file_content}</p>"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
