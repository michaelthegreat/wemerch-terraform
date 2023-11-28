resource "aws_api_gateway_rest_api" "wemerch_api_gateway_rest_api" {
  name        = "WeMerchAPI"
  description = "WeMerch API"
}

resource "aws_api_gateway_integration" "wemerch_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  resource_id = "${aws_api_gateway_method.proxy.resource_id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.wemerch_lambda.invoke_arn}"
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  resource_id   = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.root_resource_id}"
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "wemerch_lambda_root" {
  rest_api_id = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  resource_id = "${aws_api_gateway_method.proxy_root.resource_id}"
  http_method = "${aws_api_gateway_method.proxy_root.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.wemerch_lambda.invoke_arn}"
}

resource "aws_api_gateway_deployment" "wemerch_gateway_deployment" {
  depends_on = [
    "aws_api_gateway_integration.wemerch_lambda",
    "aws_api_gateway_integration.wemerch_lambda_root",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.id}"
  stage_name  = "dev"
}