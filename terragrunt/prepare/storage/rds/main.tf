module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = local.db_identifier

  engine            = "mysql"
  engine_version    = "8.0"
  port              = 3306
  instance_class    = "db.t4g.micro"
  storage_type      = "gp3"
  allocated_storage = 20 // see https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage

  manage_master_user_password = false

  db_name  = local.db_name
  username = local.db_username
  password = random_password.password.result

  vpc_security_group_ids = [
    data.terraform_remote_state.network_sg.outputs.sg_storage.id
  ]

  create_cloudwatch_log_group = true
  enabled_cloudwatch_logs_exports = [
    "error",
    "slowquery",
  ]

  # Update CA Certificate 'rds-ca-2019' (2024-08-22 EOL) to 'rds-ca-rsa2048-g1'
  # refs https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html
  ca_cert_identifier = "rds-ca-rsa2048-g1"

  # Database Deletion Protection
  copy_tags_to_snapshot = false
  deletion_protection   = false
  skip_final_snapshot   = true

  # Performance Insight
  performance_insights_enabled = false

  # DB subnet group
  create_db_subnet_group          = true
  db_subnet_group_use_name_prefix = false
  subnet_ids                      = local.db_subnet_ids

  # DB parameter group
  parameter_group_name            = local.db_parameter_group_name
  parameter_group_use_name_prefix = false

  family = "mysql8.0"

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    },
    {
      name  = "slow_query_log"
      value = "1"
    },
    {
      name  = "time_zone"
      value = "Asia/Tokyo"
    }
  ]

  # DB option group
  create_db_option_group = false

  major_engine_version = "8.0"

  # options = []
}

resource "random_password" "password" {
  length           = 40
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}