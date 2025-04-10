import json
import logging
import os
import boto3
import psycopg
from psycopg import sql
from datetime import datetime
import os
import urllib.parse

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


s3 = boto3.client('s3')

def get_secret():
    secret_name = os.environ["DB_SECRET_ARN"]
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
        raise e

    secret = get_secret_value_response['SecretString']

    # Your code goes here.
    return secret

def _process_file_content(content):
    """ Custom logic for processing json file content """
    print("processing file content...")
    content = json.loads(content)
    for c in content:
        timestamp_str = c['timestamp']
        c['timestamp'] = datetime.strptime(timestamp_str, "%Y-%m-%dT%H:%M:%SZ")
    return content

def _write_to_db(rows, db_config):
    """ Insert data into the PostgreSQL RDS database """
    connection_params = {
        'host': os.environ['PROXY_HOST'],
        'dbname': os.environ['DB_NAME'],
        'user': db_config['username'],
        'password': db_config['password'],
        'port': os.environ['DB_PORT']
    }

    try:
        with psycopg.connect(**connection_params) as conn:
            with conn.cursor() as cursor:
                logging.info("Connected to database")

                create_query = sql.SQL("""
                   CREATE TABLE IF NOT EXISTS public.transaction (
                        transaction_id UUID PRIMARY KEY,
                        client_id UUID NOT NULL,
                        account_id UUID NOT NULL,
                        amount NUMERIC(15, 2) NOT NULL,
                        status VARCHAR(50) NOT NULL,
                        timestamp TIMESTAMP NOT NULL
                    );
                """)
                cursor.execute(create_query)
                logging.info("Created transaction table if not exists")

                try:
                    insert_query = sql.SQL("""
                        INSERT INTO public.transaction (transaction_id, client_id, account_id, amount, status, timestamp)
                        VALUES (%s, %s, %s, %s, %s, %s)
                    """)

                    values = [
                        (
                            row['transaction_id'],
                            row['client_id'],
                            row['account_id'],
                            row['amount'],
                            row['status'],
                            row['timestamp']
                        )
                        for row in rows
                    ]

                    cursor.executemany(insert_query, values)
                    conn.commit()
                    logging.info(f"{len(values)} rows inserted")

                except psycopg.IntegrityError as e:
                    logging.error(f"Integrity error during batch insert: {e}")
                    conn.rollback()

                except Exception as e:
                    logging.error(f"Error during batch insert: {e}")
                    conn.rollback()

        logging.info("Data successfully inserted into RDS")

    except psycopg.Error as e:
        logging.error(f"Database connection error: {e}")

def handler(event, context):
    logger.info("Received event: " + json.dumps(event))
    
    try:
        # SQS trigger
        message_body = event['Records'][0]['body']
        message_data = json.loads(message_body)

        bucket = message_data['Records'][0]['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(message_data['Records'][0]['s3']['object']['key'], encoding='utf-8')
        print("got the key!")

    except Exception as e:
        logger.error("ERROR: Failed to process message")
        logger.error(e)
        return {
            'statusCode': 500,
            'body': json.dumps("Error processing message")
        }
    
    try:
        response = s3.get_object(Bucket=bucket, Key = key)
        file_content = response["Body"].read().decode('utf-8')
        print("read file from S3!")

    except Exception as e:
        print(f"S3 error: {e}")
        return {"statusCode": 500, "body": str(e)}

    try:
        rows = _process_file_content(file_content)

        db_config = json.loads(get_secret())
        print("Got secret!!!!")

        _write_to_db(rows, db_config)

    except Exception as e:
        print(f"Lambda error: {e}")
        return {"statusCode": 500, "body": str(e)}

    return
