data "aws_caller_identity" "current" {}

data "aws_ami" "polkadot" {
  most_recent = true
  owners      = [data.aws_caller_identity.current.account_id]

  filter {
    name   = "name"
    values = ["ami-polkadot-*"]
  }
}