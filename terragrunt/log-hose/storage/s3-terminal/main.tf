# log bucket 自体のログを採取しない、バージョニングもしない
#trivy:ignore:AVD-AWS-0089  # (LOW): Bucket has logging disabled
#trivy:ignore:AVD-AWS-0090  # (MEDIUM): Bucket does not have versioning enabled
module "log_terminal_store" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.log_terminal_bucket_name

  control_object_ownership = false
  object_ownership         = "BucketOwnerPreferred"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled    = false
    mfa_delete = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "transition after ${local.transition_days} days"
      enabled = true
      filter = {
        prefix = ""
      }
      transition = [
        {
          days          = local.transition_days
          storage_class = "GLACIER_IR"
        }
      ]
    },
    {
      id      = "delete after ${local.expiration_days} days"
      enabled = true
      filter = {
        prefix = ""
      }
      expiration = {
        days = local.expiration_days
      }
      abort_incomplete_multipart_upload_days = local.expiration_days
    }
  ]
}
