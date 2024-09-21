output "db_instance" {
  value = {
    endpoint = module.db.db_instance_endpoint
    arn      = module.db.db_instance_arn
    id       = module.db.db_instance_identifier
  }
}

output "db_password" {
  value     = random_password.password.result
  sensitive = true
}
