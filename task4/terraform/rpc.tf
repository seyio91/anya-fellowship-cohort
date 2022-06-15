module "rpc_node_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "rpc-node-sg"
  description = "Security group for use with polkadot EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.vpc_cidr]
  ingress_rules       = ["all-all"]
  egress_rules        = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      rule        = "http-80-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    }   
  ]

  tags = local.tags
}

module "rpc_node" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  for_each = toset(local.rpc_nodes)

  name = each.key

  ami                    = data.aws_ami.polkadot.id
  instance_type          = local.instance_type
  key_name               = aws_key_pair.key_pair.id
  monitoring             = true
  vpc_security_group_ids = [module.rpc_node_sg.security_group_id]
  subnet_id              = element(module.vpc.public_subnets, 0)
  user_data = templatefile("${path.module}/scripts/userdata.sh", {
    service_name = "polkadot-rpcnode"
  })

  enable_volume_tags = false

  tags = local.tags
}

resource "aws_elb" "rpc_node" {
  name = "${local.project}-elb"

  subnets = module.vpc.public_subnets
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = local.tags
}
# elb attachment
resource "aws_elb_attachment" "rpc_node" {
  for_each = module.rpc_node

  elb      = aws_elb.rpc_node.id
  instance = module.rpc_node[each.key].id
}
