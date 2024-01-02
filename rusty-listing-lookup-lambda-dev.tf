variable "rusty_listing_lookup_dev_s3_deployment_key" {
    type = string
}

resource "aws_lambda_function" "rll_lambda_dev" {
  function_name = "rusty_listing_lookup_dev"

  # The bucket name as created earlier with "aws s3api create-bucket"
  s3_bucket = var.s3_deployment_bucket
  s3_key    = var.rusty_listing_lookup_dev_s3_deployment_key

  # "main" is the filename within the zip file (main.js) and "handler"
  # is the name of the property under which the handler function was
  # exported in that file.
  handler = "bootstrap"
  runtime = "provided.al2"
  timeout = 30
  memory_size = 128

  role = var.lambda_role
  vpc_config {
    subnet_ids = [aws_subnet.wemerch_private_subnet1.id, aws_subnet.wemerch_private_subnet2.id]
    security_group_ids = [aws_security_group.wemerch_lambda_security_group.id]
  }
}

resource "aws_api_gateway_resource" "rusty_listing_lookup_dev" {
  rest_api_id = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.root_resource_id}"
  path_part   = "listing_dev"
}

resource "aws_api_gateway_method" "rusty_listing_lookup_dev" {
  rest_api_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  resource_id   = "${aws_api_gateway_resource.rusty_listing_lookup_dev.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_lambda_permission" "rusty_listing_lookup_dev_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rll_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.execution_arn}/*/*"
}