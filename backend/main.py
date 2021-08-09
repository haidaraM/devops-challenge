import json
import logging
import os
from typing import List, Dict

import boto3

# Init these resources here to take advantage of lambda context re-utilization.
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


def get_users(db_table) -> List[Dict]:
    """
    Get all users
    Note: It is NOT a best practice to scan all the content of dynamodb table. You should consider adding some index
    or use another database if you need to such kind of access to your data.
    :param db_table:
    :return:
    """
    scan = db_table.scan()  # Bad practice
    return [item for item in scan["Items"]]


def handler(event, context):
    logger.debug(event)
    users = json.dumps(get_users(table))
    logger.info(f"{len(users)} user(s) retrieved.")

    return {
        "statusCode": "200",
        'headers': {
            'Content-Type': 'application/json',
        },
        "body": users
    }


# For testing purpose
if __name__ == '__main__':
    print(handler({}, None))
