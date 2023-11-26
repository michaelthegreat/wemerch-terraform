variable "s3_deployment_bucket" {
    type = string
}

variable "s3_deployment_key" {
    type = string
}

variable "lambda_role" {
    type = string
}

resource "aws_lambda_function" "wemerch_lambda" {
  function_name = "gql"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = var.s3_deployment_bucket
  s3_key    = var.s3_deployment_key

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "main.handler"
  runtime = "nodejs18.x"

  role = var.lambda_role
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.root_resource_id}"
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}


# IAM role which dictates what other AWS services the Lambda function
# may access.
# resource "aws_iam_role" "lambda_exec" {
#   name = "serverless_example_lambda"

#   assume_role_policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "lambda.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }