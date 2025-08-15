locals {
  # Use the same firehose stream name as in the cwl-to-s3 module
  firehose_stream_name = "bastion-log-to-s3"
  
  # Get the S3 bucket name from the remote state
  s3_bucket_name = data.terraform_remote_state.storage_s3terminal.outputs.s3_log_terminal_bucket.id
}