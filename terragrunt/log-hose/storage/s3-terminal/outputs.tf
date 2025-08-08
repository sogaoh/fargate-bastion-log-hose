output "s3_log_terminal_bucket" {
  value = {
    id                   = module.log_terminal_store.s3_bucket_id
    arn                  = module.log_terminal_store.s3_bucket_arn
    regional_domain_name = module.log_terminal_store.s3_bucket_bucket_regional_domain_name
  }
}
