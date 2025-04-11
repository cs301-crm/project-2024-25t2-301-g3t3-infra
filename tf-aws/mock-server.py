import boto3
import paramiko
import random
import os
import tempfile
import logging
import json
import io
import datetime
import uuid

def get_secret():

    secret_name = "prod/tf/mock-external-server"
    region_name = "ap-southeast-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except Exception as e:
        # For a list of exceptions thrown, see
        # https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        raise e

    secret = get_secret_value_response['SecretString']

    return secret

def handler(event, context):
    """
    Lambda function that retrieves a random file from S3 and transfers it to an SFTP server.
    
    Environment variables:
    - S3_BUCKET_NAME: Name of the S3 bucket to fetch files from
    - SFTP_HOST: SFTP server hostname or IP
    - SFTP_PORT: SFTP server port (default: 22)
    - SFTP_USERNAME: SFTP username
    - SFTP_PASSWORD: SFTP password
    - SFTP_DIRECTORY: Remote directory to upload files to (default: /)
    """
    try:
        # Get environment variables
        s3_bucket_name = os.environ['S3_BUCKET_NAME'] 
        sftp_host = os.environ['SFTP_ENDPOINT']
        sftp_username = os.environ['SFTP_USERNAME']
        sftp_pkey_password = os.environ['SFTP_PKEY_PASSWORD']
        
        # Log the process start
        print(f"Starting S3 to SFTP transfer process for bucket: {s3_bucket_name}")
        
        # Initialize S3 client
        s3 = boto3.client('s3')
        
        # List all objects in the S3 bucket
        response = s3.list_objects_v2(Bucket=s3_bucket_name)
        
        # Check if the bucket has any files
        if 'Contents' not in response or len(response['Contents']) == 0:
            print(f"No files found in S3 bucket: {s3_bucket_name}")
            return {
                'statusCode': 200,
                'body': 'No files found in S3 bucket to transfer'
            }
        
        # Get a list of all files
        files = response['Contents']
        
        # Select a random file
        random_file = random.choice(files)
        file_key = random_file['Key']
        
        print(f"Selected random file: {file_key}")
        
        # Create a temporary file to store the S3 object
        with tempfile.NamedTemporaryFile(delete=False) as tmp_file:
            tmp_file_path = tmp_file.name
            
            # Download the file from S3 to the temporary file
            s3.download_file(s3_bucket_name, file_key, tmp_file_path)
            print(f"Downloaded file from S3 to temporary location: {tmp_file_path}")

        # Modify uuid
        with open(tmp_file_path, 'r') as f:
            data = json.loads(f.read())

        for mt in data:
            mt['transaction_id'] = str(uuid.uuid4()) # unique mt

        with open(tmp_file_path, 'w') as f:
            json.dump(data, f, indent=2)

        try:
            pkey_str = get_secret()

            # Create keyfile cuz transfer server needs a keyfile
            pkey_file = io.StringIO(pkey_str)

            pkey = paramiko.RSAKey.from_private_key(pkey_file, password=sftp_pkey_password)

            # Establish the SSH client
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            # Establish the SFTP client
            ssh.connect(hostname=sftp_host, username=sftp_username, pkey=pkey)
            sftp = ssh.open_sftp()

            # Upload the file to SFTP server
            put_path = f"/file_{int(datetime.datetime.now().timestamp()*1000)}.json"
            sftp.put(tmp_file_path, put_path)
            
        except Exception as sftp_error:
            print(f"SFTP error: {str(sftp_error)}")
            raise
            
        finally:
            # Remove the temporary file
            if os.path.exists(tmp_file_path):
                os.unlink(tmp_file_path)
                print(f"Removed temporary file: {tmp_file_path}")
            
            if ssh:
                ssh.close()

            if sftp:
                sftp.close()
        
        return {
            'statusCode': 200,
            'body': f'Successfully transferred file {file_key} to SFTP server'
        }
        
    except Exception as e:
        print(f"Error in Lambda function: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Error: {str(e)}'
        }