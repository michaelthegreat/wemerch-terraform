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

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.wemerch_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.wemerch_api_gateway_rest_api.execution_arn}/*/*"
}

resource "aws_security_group" "wemerch_lambda_security_group" {
  name        = "wemerch-lambda-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.wemerch.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.wemerch.cidr_block]
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.wemerch.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }

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