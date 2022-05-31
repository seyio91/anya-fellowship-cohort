locals {
  ami_map = {
    amd64 = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20220420"
    arm64 = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-20220420"
  }

  runner_url = {
    amd64 = "actions-runner-linux-x64-2.291.1.tar.gz"
    arm64 = "actions-runner-linux-arm64-2.291.1.tar.gz"
  }
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

data "aws_ami" "ubuntu_server" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name = "name"
    values = [
      local.ami_map[var.runner_architecture],
    ]
  }
}

resource "aws_security_group" "security_group" {
  name = "sec_group_github_runner"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "my-instance" {
  vpc_security_group_ids = [aws_security_group.security_group.id]
  ami                    = data.aws_ami.ubuntu_server.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.key_pair.id
  user_data = templatefile("${path.module}/scripts/ec2.sh", {
    personal_access_token = var.personal_access_token
    github_user           = var.github_user
    github_repo           = var.github_repo
    download_url          = local.runner_url[var.runner_architecture]
  })
  tags = {
    Name = "GitHub-Runner"
    Type = "terraform"
  }
}
