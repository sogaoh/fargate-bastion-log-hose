locals {
  vpc_id           = "vpc-12345678901234567"  //default VPC ID
  vpc_cidr         = "172.31.0.0/16"          //default VPC CIDR
  all_network_cidr = "0.0.0.0/0"

  external_sg_id = "sg-12345678901234567" //default VPC security group

  internal_sg_name        = "bastion-demo-internal-sg"
  internal_sg_description = "[SG] bastion demo internal"
  storage_sg_name         = "bastion-demo-storage-sg"
  storage_sg_description  = "[SG] bastion demo storage"
}