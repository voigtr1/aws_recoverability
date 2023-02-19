provider "aws" {
  region = var.aws_region
  shared_credentials_file = "C:\\Users\\q427466\\.aws\\credentials"
  profile = "udacity"
}

terraform {
  backend "local" {}
}

resource "aws_instance" "ec2_micro" {
  count = 4
  tags = {
    Name: "Udacity T2"
  }
  ami = "ami-0742b4e673072066f"
  instance_type = "t2.micro"
  subnet_id = "subnet-01321cf1c04b0bcf7"
  vpc_security_group_ids = ["sg-0b678e1189d88eda2"]
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file  = "greet_lambda.py"
  output_path = "greet_lambda.zip"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.policy.json
}

resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.terraform_lambda_func.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_iam_role_policy_attachment" "function_logging_policy_attachment" {
  role = aws_iam_role.iam_for_lambda.id
  policy_arn = aws_iam_policy.function_logging_policy.arn
}

resource "aws_iam_policy" "function_logging_policy" {
  name   = "function-logging-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename                       = "greet_lambda.zip"
  function_name                  = "UdacityRVProjectTerraformTask2"
  handler                        = "greet_lambda.lambda_handler"
  runtime                        = "python3.8"
  role                           = aws_iam_role.iam_for_lambda.arn
  environment {
    variables = {
      greeting = "[${var.aws_region}] Greeting"
    }
  }
  depends_on = [aws_iam_role.iam_for_lambda]
}