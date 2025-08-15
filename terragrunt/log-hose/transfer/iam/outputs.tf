output "cwl_to_s3_role" {
  description = "The IAM role for CloudWatch Logs to S3 via Firehose"
  value       = module.cwl_to_s3_role.generic_role
}

output "subscription_filter_role" {
  description = "The IAM role for CloudWatch Logs subscription filter"
  value       = module.subscription_filter_role.generic_role
}
