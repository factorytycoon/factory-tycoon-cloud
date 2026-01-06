import json

# TODO: Implement OpenSearch -> MariaDB sync using the provided environment variables:
# - OPENSEARCH_ENDPOINT, OPENSEARCH_MASTER_USER, OPENSEARCH_MASTER_PASSWORD
# - MARIADB_URL, MARIADB_USERNAME, MARIADB_PASSWORD

def lambda_handler(event, context):
    return {
        "statusCode": 501,
        "body": json.dumps({"message": "Not implemented yet"}),
    }
