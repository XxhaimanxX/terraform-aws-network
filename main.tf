###########
## VPC
###########

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "main_vpc"
  }
}

#Creating public subnet
resource "aws_subnet" "public_sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_sub_cidr_block
  availability_zone = var.az_1
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet"
  }
}
#Creating public subnet
resource "aws_subnet" "public_sub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_sub2_cidr_block
  availability_zone = var.az_2
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet_2"
  }
}
#Creating private subnet
resource "aws_subnet" "private_sub" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_sub_cidr_block
  availability_zone = var.az_1

  tags = {
    Name = "Private Subnet"
  }
}
#Creating private subnet
resource "aws_subnet" "private_sub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_sub2_cidr_block
  availability_zone = var.az_2

  tags = {
    Name = "Private Subnet"
  }
}
#Creating Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
#Creating Elastic IP
resource "aws_eip" "eip_nat" {
  depends_on = [aws_internet_gateway.gw]
}
#Creating NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.eip_nat.id
  subnet_id     = aws_subnet.public_sub.id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.gw]
}
#Creating Private Route Table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }
}
#Creating Public Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}
#Attaching subnets to route table
resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private_route_table.id
}
#Attaching subnets to route table
resource "aws_route_table_association" "private_association2" {
  subnet_id      = aws_subnet.private_sub2.id
  route_table_id = aws_route_table.private_route_table.id
}
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "public_association2" {
  subnet_id      = aws_subnet.public_sub2.id
  route_table_id = aws_route_table.public_route_table.id
}
#Creating network interfaces
resource "aws_network_interface" "net_interface" {
  subnet_id = aws_subnet.private_sub.id
  security_groups = ["${aws_security_group.allow_http.id}" , "${aws_security_group.allow_ssh.id}"]
  count = 2
  tags = {
    Name = "sub_net_interface${count.index}"
  }
}
resource "aws_network_interface" "net_interface2" {
  subnet_id = aws_subnet.private_sub2.id
  security_groups = ["${aws_security_group.allow_http.id}" , "${aws_security_group.allow_ssh.id}"]
  count = 2
  tags = {
    Name = "sub2_net_interface${count.index}"
  }
}

###########
## Security groups
###########

resource "aws_security_group" "allow_http" {
  name  =  "allow_http"
  description = "Allow HTTP requests"
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "allow_http"
  }
}

resource "aws_security_group" "allow_ssh" {
  name  =  "allow_ssh"
  description = "Allow SSH requests"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "allow_http_ingress" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.allow_http.id}"
}

resource "aws_security_group_rule" "allow_ssh_ingress" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.allow_ssh.id}"
}

resource "aws_security_group_rule" "allow_all_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.allow_http.id}"
}