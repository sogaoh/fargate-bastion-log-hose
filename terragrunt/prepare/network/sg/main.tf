module "internal_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name            = local.internal_sg_name
  use_name_prefix = false
  description     = local.internal_sg_description

  vpc_id = local.vpc_id

  ingress_cidr_blocks = [
    local.vpc_cidr,
  ]

  ingress_with_source_security_group_id = [
    { //HTTP
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = local.external_sg_id
    }
  ]
  ingress_with_cidr_blocks = [
    { //HTTPS
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = local.vpc_cidr
    },
    { //SSH
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = local.vpc_cidr
    },
    { //Laravel
      from_port   = 9000
      to_port     = 9000
      protocol    = "tcp"
      cidr_blocks = local.vpc_cidr
    },
    { //for `ping`
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = local.vpc_cidr
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      # tfsec:ignore:aws-ec2-no-public-egress-sgr
      cidr_blocks = local.all_network_cidr
    }
  ]
}

module "storage_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name            = local.storage_sg_name
  use_name_prefix = false
  description     = local.storage_sg_description

  vpc_id = local.vpc_id

  ingress_cidr_blocks = [
    local.vpc_cidr,
  ]

  ingress_with_source_security_group_id = [
    { //MySQL
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      source_security_group_id = module.internal_sg.security_group_id
    },
    { //Redis
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      source_security_group_id = module.internal_sg.security_group_id
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      # tfsec:ignore:aws-ec2-no-public-egress-sgr
      cidr_blocks = local.all_network_cidr
    }
  ]
}
