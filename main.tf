data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnet" "subnet1" {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = var.availability_zone
}

# Creating Security Group
resource "aws_security_group" "sg" {
  name        = "misyuro_sg"
  description = "Security group for VPC Endpoint"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creating VPS Endpoint
resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id             = data.aws_vpc.vpc.id
  subnet_ids         = [data.aws_subnet.subnet1.id]
  service_name       = "com.amazonaws.us-east-1.execute-api"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.sg.id]
  ip_address_type    = "ipv4"
}

# Creating DynamoDB Table
resource "aws_dynamodb_table" "dynamodb_table" {
  name           = "DynamoDB_test"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"
  attribute {
    name = "Id"
    type = "S"
  }
}

# Adding Items to DynamoDB Table
resource "aws_dynamodb_table_item" "item1" {
  table_name = aws_dynamodb_table.dynamodb_table.name
  hash_key   = aws_dynamodb_table.dynamodb_table.hash_key
  item       = <<ITEM
{
  "Id": {"S": "1"},
  "Firstname": {"S": "Nikita"},
  "LastName": {"S": "Misyuro"},
  "Age": {"S": "20"},
  "Department": {"S": "DevOps"}
}
ITEM
}

resource "aws_dynamodb_table_item" "item2" {
  table_name = aws_dynamodb_table.dynamodb_table.name
  hash_key   = aws_dynamodb_table.dynamodb_table.hash_key
  item       = <<ITEM
{
  "Id": {"S": "2"},
  "Firstname": {"S": "Slava"},
  "LastName": {"S": "Gordienko"},
  "Age": {"S": "22"},
  "Department": {"S": "DevOps"}
}
ITEM
}

resource "aws_dynamodb_table_item" "item3" {
  table_name = aws_dynamodb_table.dynamodb_table.name
  hash_key   = aws_dynamodb_table.dynamodb_table.hash_key
  item       = <<ITEM
{
  "Id": {"S": "3"},
  "Firstname": {"S": "Vitaliy"},
  "LastName": {"S": "Korzun"},
  "Age": {"S": "38"},
  "Department": {"S": "DevSecOps"}
}
ITEM
}

# Create Lambda Function
resource "aws_lambda_function" "lambda" {
  filename         = "lambda_function.zip"
  function_name    = "lambda_function"
  role             = "arn:aws:iam::556165283018:role/lambda_role"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# Creating Rest API Gateway
resource "aws_api_gateway_rest_api" "restapi" {
  name        = "api_gateway_rest"
  description = "This is my API for demonstration purposes"
  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.vpc_endpoint.id]
  }
}

# Creating Resource
resource "aws_api_gateway_resource" "api_gateway_resource" {
  parent_id   = aws_api_gateway_rest_api.restapi.root_resource_id
  path_part   = "list"
  rest_api_id = aws_api_gateway_rest_api.restapi.id
}

# Create Method for resource
resource "aws_api_gateway_method" "method" {
  rest_api_id   = aws_api_gateway_rest_api.restapi.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Intergrate lambda Function with Method
resource "aws_api_gateway_integration" "lambda_integration_1" {
  rest_api_id             = aws_api_gateway_rest_api.restapi.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
}
