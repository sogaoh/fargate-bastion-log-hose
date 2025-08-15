locals {
  firehose_stream_name = var.firehose_stream_name

  firehose_delivery_log_retention_days = 3

  # Log group to subscribe to
  source_log_group_name = var.source_log_group_name

  # Filter pattern for the subscription filter
  subscription_filter_pattern = "" # Empty string means all log events

  lambda_function_name      = "cwl-to-s3-processor"
  lambda_log_retention_days = 3
}
