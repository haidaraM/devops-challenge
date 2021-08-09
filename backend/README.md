# Backend Lambda function

A lambda scanning a return the content of a dynamodb table. It used as an integration target for an HTTP API.

**Note: It is NOT a best practice to scan all the content of dynamodb table. You should consider adding some index or
use another database if you need to such kind of access to your data.**

## Requirements

- An environment variable `DYNAMODB_TABLE` containing the name of the dynamodb table
- An IAM role granting `dynamodb:Scan` to this table