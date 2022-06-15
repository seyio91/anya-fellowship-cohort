locals {
  availability_zone = "${local.region}a"
  project           = "anya"
  instance_type     = "t2.medium"
  region            = "eu-west-2"
  boot_nodes        = ["${local.project}-bootnode-1", "${local.project}-bootnode-2"]
  rpc_nodes         = ["${local.project}-rpcnode-1", "${local.project}-rpcnode-2"]
  vpc_cidr          = "10.0.0.0/16"
  tags = {
    Terraform   = "true"
    Project     = local.project
    Environment = "test"
  }
}




module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.project}-vpc"
  cidr = local.vpc_cidr

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = local.tags
}


module "boot_node_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  # version = "~> 4.0"

  name        = "${local.project}-boot-node-sg"
  description = "Security group for polkadot nodes"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.vpc_cidr]
  ingress_rules       = ["all-all"]
  egress_rules        = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    }   
  ]
  tags = local.tags
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "key"
  public_key = tls_private_key.key.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.key.private_key_pem}' > ./key.pem"
  }
}

module "boot_node" {
  source   = "terraform-aws-modules/ec2-instance/aws"
  version  = "~> 3.0"
  for_each = toset(local.boot_nodes)

  name                   = each.key
  ami                    = data.aws_ami.polkadot.id
  instance_type          = local.instance_type
  key_name               = aws_key_pair.key_pair.id
  monitoring             = true
  vpc_security_group_ids = [module.boot_node_sg.security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 0)
  user_data = templatefile("${path.module}/scripts/userdata.sh", {
    service_name = "polkadot-bootnode"
  })

  enable_volume_tags = false

  tags = local.tags
}
