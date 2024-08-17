generate "terraform_version" {
  path      = ".terraform-version"
  if_exists = "overwrite_terragrunt"
  contents  = "1.9.4"
}

generate "backend" {
  path      = "_backend.tf"
  if_exists = "skip"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
}
EOF
}

generate "provider" {
  path      = "_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = var.region
  profile = var.profile

  shared_credentials_files = ["~/.aws/credentials"]

  default_tags {
    Managed_by  = "Terragrunt"
  }
}
EOF
}

generate "variables" {
  path      = "_variables.tf"
  if_exists = "skip"
  contents  = <<EOF
variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "profile" {
  type    = string
  default = ""
}
EOF
}


# 子ディレクトリの terragrunt.hcl の設定を含める
include {
  path = find_in_parent_folders()
}

# 共通の locals 設定
locals {
}

# 共通の inputs
inputs = {
}
