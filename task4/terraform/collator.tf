module "collator_node_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "collator-node-sg"
  description = "Security group for polkadot Nodes"
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

module "collator_node" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "${local.project}-collator-node"

  ami                    = data.aws_ami.polkadot.id
  instance_type          = local.instance_type
  key_name               = aws_key_pair.key_pair.id
  monitoring             = true
  vpc_security_group_ids = [module.collator_node_sg.security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 1)
  user_data = templatefile("${path.module}/scripts/userdata.sh", {
    service_name = "polkadot-collatornode"
  })

  enable_volume_tags = false

  tags = local.tags
}
