


# CREATING VPC
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
   
   tags = {
    Name = "Terr-vpc"   
}
}

# USING COUNT TO CREATE PUBLIC SUBNETS
resource "aws_subnet" "public_subnet" {
    count = 2

  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = var.public_cidrs[count.index] 
  availability_zone = [local.azs[0], local.azs[1]][count.index] 
  map_public_ip_on_launch = true #public ip

  tags = {
    Name = "terr_subnet_${count.index + 1}" 
    
}
}

##Creating EC2
resource "aws_instance" "EC2" {
    count = 2
  ami           = "ami-00eeedc4036573771"
  instance_type = "t2.micro"
  key_name = "us-east-2"   // "us-east-2" == this is the name of my key pair without the .pem
  
availability_zone = [local.azs[0], local.azs[1]][count.index] 


user_data = <<-EOF
    #!/bin/bash# sleep until instance is ready
    until [[ -f /var/lib/cloud/instance/boot-finished ]]; do
     sleep 1
        done# install nginx
    apt-get update
    apt-get -y install nginx# make sure nginx is started
    service nginx start
   
    EOF

  tags = {
    Name = "EC2_${count.index + 1}" 
  }
}

#Create a security group to allow SSH access and HTTP access
resource "aws_security_group" "ssh-allowed" {
    vpc_id = aws_vpc.my-vpc.id
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Ideally best to use your machines' IP. However if it is dynamic you will need to change this in the vpc every so often. 
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


 ##Create Internet Gateway for the VPC
  resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id
  }


##Create a custom route table for the VPC
  resource "aws_route_table" "public-crt" {
  vpc_id = aws_vpc.my-vpc.id
  route {
    cidr_block = "0.0.0.0/0"                      //associated subnet can reach everywhere
    gateway_id = aws_internet_gateway.igw.id //CRT uses this IGW to reach internet
  }
  tags = {
    Name = "public-crt"
  }
}

##Associate the route table with the public subnet
resource "aws_route_table_association" "crta-public-subnet" {
    count = 2
  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  # aws_subnet.public_subnet[count.index] 
  route_table_id = aws_route_table.public-crt.id
}


# ##Creating a network interface
resource "aws_network_interface" "nginx_server-ni" {
    count = 2
    subnet_id = "${element(aws_subnet.public_subnet.*.id, count.index)}"
    # private_ip = ["10.0.1.50"]
    security_groups = [aws_security_group.ssh-allowed.id]
   
}




