variable "public_subnet_id" {}
variable "bastion_sg" {}

resource "aws_instance" "bastion" {
  ami                    = "ami-0b5a4445ada4a59b1" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg]
  key_name               = "cs301 bastion"

  user_data = <<-EOL
  #!/bin/bash -xe

  sudo yum install -y postgresql16 postgresql16-server
  sudo /usr/bin/postgresql-setup --initdb
  sudo systemctl start postgresql
  sudo systemctl enable postgresql
  EOL

  tags = {
    Name = "bastion-host"
  }
}
