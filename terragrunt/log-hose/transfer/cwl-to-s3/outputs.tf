output "firehose_delivery_stream" {
  description = "The Kinesis Firehose delivery stream that transfers CloudWatch Logs to S3"
  value = {
    arn  = aws_kinesis_firehose_delivery_stream.cwl_to_s3.arn
    name = aws_kinesis_firehose_delivery_stream.cwl_to_s3.name
  }
}

output "firehose_delivery_log_group" {
  description = "The CloudWatch Log Group for the Firehose delivery stream"
  value = {
    arn  = module.firehose_delivery_log_group.cloudwatch_log_group_arn
    name = module.firehose_delivery_log_group.cloudwatch_log_group_name
  }
}

output "firehose_delivery_role" {
  description = "The IAM role used by the Firehose delivery stream"
  value       = module.firehose_delivery_role.generic_role
}

output "subscription_filter_role" {
  description = "The IAM role for CloudWatch Logs subscription filter"
  value       = module.subscription_filter_role.generic_role
}

output "cwl_to_firehose_role" {
  description = "The IAM role for CloudWatch Logs to write to Firehose"
  value       = module.cwl_to_firehose_role.generic_role
}
