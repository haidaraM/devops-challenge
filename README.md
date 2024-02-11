# DevOps challenge

A Project to demonstrate how to deploy a basic modern web app on AWS with Terraform.

May be used as a starting point for a more complete application. This stack should fall under AWS free tier (the first
12 months). Some components were not included because they don't have a free tier.

## Background and requirements

You have been asked to create a website for a modern company that has recently migrated their entire infrastructure to
AWS. They want you to demonstrate a basic website with some text and an image, hosted and managed using modern standards
and practices in AWS.

You can create your own application, or use open source or community software. The proof of concept is to demonstrate
**hosting, managing, and scaling an enterprise-ready system**. This is not about website content or UI.

Requirements:

- Deliver the tooling to set up an application which displays a web page with text and an image in AWS. (AWS free-tier
  is fine)
- Provide and document a mechanism for scaling the service and delivering the content to a larger audience.
- Source code should be provided via a publicly accessible Github repository.
- Provide basic documentation to run the application along with any other documentation you think is appropriate.

## Implementation

From the background, I will deploy a simple Single Page Application (SPA) with a backend fetching some data from a
database.

As the goal is to demonstrate a basic website on AWS, I have kept things simple by using a **serverless architecture**
with the AWS following services:

- A S3 bucket to host the static files. [Angular](https://angular.io/) is used to generate the frontend that will
  display an image describing the architecture used and some data from a Dynamodb Table. The files in the bucket are NOT
  public. The bucket is used as an origin for a cloudfront distribution.
- A Cloudfront distribution will serve the web application in front of the S3 bucket. Using cloudfront will **speed up
  the website loading**: the static content (HTML, CSS and JS) will be available from AWS Data centers around the
  world. **No action required to scale the frontend**.   
  The distribution price class is set `PriceClass_100` (North America, Europe and Israel). It defines on which edge
  location Cloudfront will serve the requests. In order to target another
  audience, [change the price class.](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html)

  Cloudfront also allows us to set up a custom domain for our website (NOT implemented in this project).
- An S3 bucket for Cloudfront standard access logs. It can be connected
  to [AWS Athena](https://aws.amazon.com/blogs/big-data/easily-query-aws-service-logs-using-amazon-athena/) for further
  analysis.
- A Lambda function will be used as a backend behind an HTTP API powered by AWS API Gateway. This API will expose a
  single endpoint to get the users (`/users`) in the Dynamodb table described below.   
  If your backend and traffic is expected to grow significantly in size and complexity, you may consider using a Docker
  container on ECS. There is also a quota on
  [Lambda function concurrent executions](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html) that
  we need to be aware of and monitor when serving the website to a larger audience.
- Xray for tracing on the Lambda function. Lambda logs are pushed to a Cloudwatch log group.
- A Dynamodb table will store the data. The data consists of some fake data about users (see [users.json](backend/users.json)).
  Terraform reads that file and put the items in Dynamodb.  
  A provisioned billing mode is used for this project. Depending on your usage, you may
  consider [On Demand mode](https://aws.amazon.com/blogs/aws/amazon-dynamodb-on-demand-no-capacity-planning-and-pay-per-request-pricing/)
  or increase the provisioned capacities.

![Architecture image](img/architecture.png)

### Screenshot

![Web page image](img/screenshot.png)

The authentication is not covered by this project. For those who want to go further about authentication, go check
out [AWS Cognito](https://aws.amazon.com/fr/cognito/) and/or [AWS Amplify](https://aws.amazon.com/fr/cognito/).

### Terraform

Terraform is used to deploy the architecture above and copy the static files to S3. The static files are copied only
when:

- The S3 bucket has changed
- The `index.html` has changed (a new build has been made with some changes in the files)
- The `config.json` has changed. `config.json` is the file containing some configuration such as the API URL and the
  environment name. The template build of this file is located
  at [frontend/src/assets/config.tpl.json.](frontend/src/assets/config.tpl.json)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | ~> 2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5 |
| <a name="requirement_null"></a> [null](#requirement\_null) | ~> 3 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | ~> 2 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5 |
| <a name="provider_null"></a> [null](#provider\_null) | ~> 3 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.http_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_integration.lambda_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.default_stage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_cloudfront_distribution.website](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_identity.origin_access_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_identity) | resource |
| [aws_cloudwatch_log_group.log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.dynamodb_throttled_requests](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.lambda_errors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_dynamodb_table.users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_dynamodb_table_item.users](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table_item) | resource |
| [aws_iam_role.lambda_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_dynamodb_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.lambda_cloudwatch_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.lambda_xray_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.api_backend](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_permission.allow_apigateway_to_invoke_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_s3_bucket.cloudfront_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.website](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.cloudfront_logs_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.cf_access_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.origin_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_object.architecture_img](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_sns_topic.alerting](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [null_resource.deploy_to_s3](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [archive_file.lambda_package](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_canonical_user_id.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/canonical_user_id) | data source |
| [aws_cloudfront_cache_policy.cache_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_log_delivery_canonical_user_id.awslogsdelivery](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_log_delivery_canonical_user_id) | data source |
| [aws_iam_policy_document.lambda_dynamodb_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.origin_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region to deploy to | `string` | `"eu-west-2"` | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | The price class for this distribution. One of PriceClass\_All, PriceClass\_200, PriceClass\_100. See https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html | `string` | `"PriceClass_100"` | no |
| <a name="input_default_tags"></a> [default\_tags](#input\_default\_tags) | Default tags to apply to resources | `map(string)` | <pre>{<br>  "app": "devops-challenge"<br>}</pre> | no |
| <a name="input_env"></a> [env](#input\_env) | Name of the environment | `string` | `"dev"` | no |
| <a name="input_front_build_dir"></a> [front\_build\_dir](#input\_front\_build\_dir) | The folder where the frontend has been built | `string` | `"frontend/dist/devops-challenge/"` | no |
| <a name="input_lambda_directory"></a> [lambda\_directory](#input\_lambda\_directory) | The directory containing lambda | `string` | `"backend"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A prefix appended to each resource | `string` | `"devops-challenge"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudfront_url"></a> [cloudfront\_url](#output\_cloudfront\_url) | Cloudfront URL to access the website |
| <a name="output_frontend_bucket_name"></a> [frontend\_bucket\_name](#output\_frontend\_bucket\_name) | Name of the bucket containing the static files |
| <a name="output_users_endpoint"></a> [users\_endpoint](#output\_users\_endpoint) | API Gateway url to access users |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


### Repository: monorepo structure

This mono repository has the following structure:

```shell
.
├── backend # The backend in Lambda
│   ├── README.md
│   ├── main.py
│   └── users.json # Some fake users list
├── frontend # Angular frontend application
│   ├── src
│   ├── README.md
│   ├── angular.json
│   ├── karma.conf.js
│   ├── package-lock.json
│   ├── package.json
│   ├── tsconfig.app.json
│   ├── tsconfig.json
│   └── tsconfig.spec.json
├── img
│   ├── architecture.drawio
│   ├── architecture.png
│   └── screenshot.png
├── README.md
├── backend.tf # Backend resources: lambda function, API Gateway...
├── data.tf # Data sources
├── frontend.tf # Frontend resources: S3 buckets, cloudfront
├── main.tf # Terraform Providers 
├── monitoring.tf # SNS, alarms
├── outputs.tf # Terraform outputs
└── variables.tf # Variables for terraform
```

### Deployment

To deploy the application, you need:

- An AWS account and an IAM user with the required permissions. The user's credentials need to be configured in your
  terminal.
- [Optional] Angular CLI and Node to build the frontend. You can find the build in
  the [releases page](https://github.com/haidaraM/devops-challenge/releases).
- AWS CLI to sync the static files to S3
- Terraform CLI

In case you want to build the frontend:

```shell
npm install -g @angular/cli
cd frontend
npm install
ng build # Will generate the artifacts in dist/devops-challenge
```

Otherwise, download the zip `front-devops-challenge-v1.0.0.zip` from the releases page and extract it in the `frontend`
folder. You should have this structure `front/dist/devops-challenge`.

To deploy the application, from the root folder of the repository:

```shell
# Should export the required AWS variables before
terraform init
terraform apply # Then enter yes
```

The output should look like something like this:

```shell
cloudfront_url = "https://d1n3neitxvtko9.cloudfront.net"
frontend_bucket_name = "devops-challenge-xyypd"
users_endpoint = "https://f08q1l967c.execute-api.eu-west-2.amazonaws.com/users"
```

### Security

As mentioned above, no authentication mechanism is provided by this project. If the web application is meant to serve
some restricted content/features, AWS Cognito may help.  
The [allowed origins to access the API](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-cors.html)
is also set to `*` for simplicity. One way to avoid cross origins requests is to put the API Gateway as another origin
behind the same cloudfront distribution at `/api`.

To go further, one can enable AWS Web Application Firewall (WAF) on the cloudfront distribution and the API Gateway (if
using a REST API). It will protect against some common web exploits and bots.

For restricting data access, a key KMS with a restricted policy can be applied to the Dynamodb Table. Only the necessary
services, persons should have access to this key.

### Monitoring/Alerting

Some components and metrics to monitor:

- Alarm on Lambda function error metric (implemented)
- Alarms on Cloudfront metrics: 4xxErrorRate, 5xxErrorRate
- Alarms Dynamodb throttle metrics (implemented), ConsumedReadCapacityUnits and ConsumedWriteCapacityUnits
- API Gateway metrics

These alarms can be configured in Cloudwatch with an SNS topic destination (implemented). The alarm names start with the
environment name to quickly identify which environnement is affected by the alarm.

As X-ray is enabled on the Lambda function, you may understand how your Lambda is behaving regarding its access to other
services.

### Automation

As everything is done with Terraform, we could implement the following jobs in any CI/CD tool:

- Jobs for linting/validation:
    - Lint on backend: pylint,...
    - Lint on frontend: tslint,...
    - Lint on Terraform: tflint, terraform validate
- Build the frontend and export the build as artifacts:
- Tests:
    - Unit tests on the backend
    - E2E tests on the frontend by mocking the backend
- Terraform init/plan (needs the build artifacts)
- Terraform apply (needs the build artifacts). It may be a manual job

Before launching Terraform in a pipeline, we should first set up a S3 backend (for example) to store the state file.