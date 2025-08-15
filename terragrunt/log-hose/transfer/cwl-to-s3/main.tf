# refs: https://n-s.tokyo/2025/03/20250301/

resource "aws_kinesis_firehose_delivery_stream" "cwl_to_s3" {
  destination = "extended_s3"
  name        = local.firehose_stream_name

  extended_s3_configuration {
    role_arn            = module.firehose_delivery_role.generic_role.arn
    bucket_arn          = data.terraform_remote_state.storage_s3terminal.outputs.s3_log_terminal_bucket.arn
    buffering_interval  = 300
    buffering_size      = 5
    compression_format  = "GZIP"
    custom_time_zone    = "Asia/Tokyo"
    prefix              = "logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "error/!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "/aws/kinesisfirehose/${local.firehose_stream_name}"
      log_stream_name = "DestinationDelivery"
    }

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"
        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = data.aws_lambda_function.cwl_processor.arn
        }
      }
    }
  }
}

# CloudWatch Logs subscription filter
resource "aws_cloudwatch_log_subscription_filter" "cwl_to_firehose" {
  name            = "cwl-to-firehose"
  log_group_name  = local.source_log_group_name
  filter_pattern  = local.subscription_filter_pattern
  destination_arn = aws_kinesis_firehose_delivery_stream.cwl_to_s3.arn
  role_arn        = module.cwl_to_firehose_role.generic_role.arn
}

data "aws_lambda_function" "cwl_processor" {
  function_name = local.lambda_function_name
}
module "lambda_log_group" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/log-group"

  name              = "/aws/lambda/${local.lambda_function_name}"
  retention_in_days = local.lambda_log_retention_days
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "firehose_delivery_log_group" {
  source = "terraform-aws-modules/cloudwatch/aws//modules/log-group"

  name              = "/aws/kinesisfirehose/${local.firehose_stream_name}"
  retention_in_days = local.firehose_delivery_log_retention_days
}

module "firehose_delivery_role" {
  source = "../../../tf-modules/generic-role"

  service = "firehose.amazonaws.com"

  generic_role_name = "CwlToS3Role"
  generic_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess",
    aws_iam_policy.s3_rw.arn,
    aws_iam_policy.lambda_invoke.arn,
  ]
}

resource "aws_iam_policy" "s3_rw" {
  name   = "CwlToS3_S3Rw"
  policy = data.aws_iam_policy_document.s3_rw.json
}
data "aws_iam_policy_document" "s3_rw" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:AbortBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      data.terraform_remote_state.storage_s3terminal.outputs.s3_log_terminal_bucket.arn,
      "${data.terraform_remote_state.storage_s3terminal.outputs.s3_log_terminal_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "lambda_invoke" {
  name   = "CwlToS3_LambdaInvoke"
  policy = data.aws_iam_policy_document.lambda_invoke.json
}
data "aws_iam_policy_document" "lambda_invoke" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration",
    ]
    resources = [
      data.aws_lambda_function.cwl_processor.arn,
      "${data.aws_lambda_function.cwl_processor.arn}:*",
    ]
  }
}

# Lambda function execution role for CloudWatch Logs subscription filter
module "subscription_filter_role" {
  source = "../../../tf-modules/generic-role"

  service           = "lambda.amazonaws.com"
  generic_role_name = "CwlToS3SubscriptionFilterRole"
  generic_policy_arns = [
    aws_iam_policy.subscription_filter.arn,
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}

# Policy for the subscription filter role
resource "aws_iam_policy" "subscription_filter" {
  name        = "CwlToS3SubscriptionFilterPolicy"
  description = "Policy for CloudWatch Logs subscription filter to Firehose"
  policy      = data.aws_iam_policy_document.subscription_filter.json
}

# Policy document for the subscription filter role
data "aws_iam_policy_document" "subscription_filter" {
  version = "2012-10-17"

  statement {
    effect = "Allow"
    actions = [
      "logs:PutSubscriptionFilter",
      "logs:DescribeSubscriptionFilters",
      "logs:DeleteSubscriptionFilter",
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]
    resources = [
      "arn:aws:firehose:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:deliverystream/${local.firehose_stream_name}",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      module.firehose_delivery_role.generic_role.arn,
    ]
  }
}

# IAM role for CloudWatch Logs to write to Firehose
module "cwl_to_firehose_role" {
  source = "../../../tf-modules/generic-role"

  service           = "logs.amazonaws.com"
  generic_role_name = "CwlToFirehoseRole"
  generic_policy_arns = [
    aws_iam_policy.cwl_to_firehose.arn,
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
  ]
}
# IAM policy for CloudWatch Logs to write to Firehose
resource "aws_iam_policy" "cwl_to_firehose" {
  name   = "CwlToFirehoseRolePolicy"
  policy = data.aws_iam_policy_document.cwl_to_firehose.json
}
data "aws_iam_policy_document" "cwl_to_firehose" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
    resources = [
      aws_kinesis_firehose_delivery_stream.cwl_to_s3.arn
    ]
  }
}
