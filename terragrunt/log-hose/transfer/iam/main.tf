# CwlToS3Role implementation
# Reference: https://github.com/htnosm/terraform-aws-cloudwatch-logs-to-s3/blob/main/aws_iam_role.tf

# Data sources for AWS region and caller identity
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IAM role for CloudWatch Logs to S3 via Firehose
module "cwl_to_s3_role" {
  source = "../../../tf-modules/generic-role"
  
  service = "firehose.amazonaws.com"
  generic_role_name = "CwlToS3Role"
  generic_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonKinesisFirehoseFullAccess",
    aws_iam_policy.s3_access.arn,
  ]
  tags = {
    Name = "CwlToS3Role"
  }
}

# S3 access policy for the CwlToS3Role
resource "aws_iam_policy" "s3_access" {
  name        = "CwlToS3_S3Access"
  description = "Policy for S3 access from CloudWatch Logs to S3 via Firehose"
  policy      = data.aws_iam_policy_document.s3_access.json
}

# S3 access policy document
data "aws_iam_policy_document" "s3_access" {
  version = "2012-10-17"
  
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}",
      "arn:aws:s3:::${local.s3_bucket_name}/*",
    ]
  }
}

# Lambda function execution role for CloudWatch Logs subscription filter
module "subscription_filter_role" {
  source = "../../../tf-modules/generic-role"
  
  service = "lambda.amazonaws.com"
  generic_role_name = "CwlToS3SubscriptionFilterRole"
  generic_policy_arns = [
    aws_iam_policy.subscription_filter_policy.arn,
  ]
  tags = {
    Name = "CwlToS3SubscriptionFilterRole"
  }
}

# Policy for the subscription filter role
resource "aws_iam_policy" "subscription_filter_policy" {
  name        = "CwlToS3SubscriptionFilterPolicy"
  description = "Policy for CloudWatch Logs subscription filter to Firehose"
  policy      = data.aws_iam_policy_document.subscription_filter_policy.json
}

# Policy document for the subscription filter role
data "aws_iam_policy_document" "subscription_filter_policy" {
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
      module.cwl_to_s3_role.generic_role.arn,
    ]
  }
}