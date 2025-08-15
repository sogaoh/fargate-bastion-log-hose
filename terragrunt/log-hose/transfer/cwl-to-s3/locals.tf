locals {
  firehose_stream_name = "bastion-log-to-s3"

  firehose_delivery_log_retention_days = 3

  # Log group to subscribe to
  source_log_group_name = "/aws/ecs/prd/bastion-logs"

  # Filter pattern for the subscription filter
  subscription_filter_pattern = "" # Empty string means all log events
}
