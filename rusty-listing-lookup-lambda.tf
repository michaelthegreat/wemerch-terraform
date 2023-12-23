variable "s3_deployment_bucket" {
    type = string
}

variable "rusty_listing_lookup_s3_deployment_key" {
    type = string
}

resource "aws_lambda_function" "rll_lambda" {
  function_name = "rusty_listing_lookup"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = var.s3_deployment_bucket
  s3_key    = var.s3_deployment_key

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "dist/handlers.gql"
  runtime = "nodejs18.x"
  timeout = 30
  memory_size = 256

  role = var.lambda_role
  vpc_config {
    subnet_ids = [aws_subnet.wemerch_private_subnet1.id, aws_subnet.wemerch_private_subnet2.id]
    security_group_ids = [aws_security_group.wemerch_lambda_security_group.id]
  }
}

resource "aws_api_gateway_resource" "rusty_listing_lookup" {
  rest_api_id = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.root_resource_id}"
  path_part   = "listings"
}

resource "aws_api_gateway_method" "rusty_listing_lookup" {
  rest_api_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  resource_id   = "${aws_api_gateway_resource.rusty_listing_lookup.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_lambda_permission" "rusty_listing_lookup_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rll_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.execution_arn}/*/*"
}