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
        type = "Decompression"
        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }

      processors {
        type = "AppendDelimiterToRecord"
      }
    }
  }
}

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
