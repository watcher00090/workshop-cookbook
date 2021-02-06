resource "aws_vpc" "mayalearning" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "mayalearning"
  }
}

resource "aws_subnet" "mayalearning" {
  vpc_id     = aws_vpc.mayalearning.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "mayalearning"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.mayalearning.id

  ingress {
    description = "SSH from Anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_internet_gateway" "mayalearning-env-gw" {
  vpc_id = aws_vpc.mayalearning.id
tags = {
    Name = "mayalearning-env-gw"
  }
}

resource "aws_route_table" "route-table-mayalearning" {
  vpc_id = aws_vpc.mayalearning.id
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mayalearning-env-gw.id
  }
tags = {
    Name = "mayalearning-route-table"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.mayalearning.id
  route_table_id = aws_route_table.route-table-mayalearning.id
}

//servers.tf
resource "aws_instance" "mayalearning-ec2-instance" {
  ami = "ami-0074ee617a234808d"
  instance_type = "m5ad.large"
//  instance_type = "c5ad.xlarge"
  key_name = "MayaLearning"
  security_groups = [aws_security_group.allow_ssh.id]
  count = 3
tags = {
    Name = "mayalearning-${format("%d", count.index + 1)}"
  }
subnet_id = aws_subnet.mayalearning.id
}

output "instance_ips" {
  value = aws_instance.mayalearning-ec2-instance.*.public_ip
}

//output "lb_address" {
//  value = aws_instance.mayalearning-ec2-instance[count.index].public_dns
//}
