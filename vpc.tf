terraform {
required_providers {
aws = {
source = "hashicorp/aws"
version = "~> 4.16"

}
}
required_version = ">=1.2.0"
}

provider "aws" {
region = "us-east-1"
}

resource "aws_vpc" "virtualprivatecloud" {
	cidr_block = "10.0.0.0/16"
	instance_tenancy = "default"
	tags = {
	Name = "VPC1"
}
}

resource "aws_subnet" "publicsubnet" {
	vpc_id = aws_vpc.virtualprivatecloud.id
	cidr_block = "10.0.1.0/24"
	tags = {
	Name = "publicsubnet1"
}
}

resource "aws_subnet" "privatesubnet" {
	vpc_id = aws_vpc.virtualprivatecloud.id
	cidr_block = "10.0.2.0/24"
	tags = {
	Name = "privatesubnet1"
}
}

resource "aws_security_group" "securitygroup" {
	name = "securitygroup1"
	description = "sg for vpc1"
	vpc_id = aws_vpc.virtualprivatecloud.id

	ingress {
		description = "inbound rules for sg"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]

}
	tags = {
	Name = "securitygroup1"
}
}

resource "aws_internet_gateway" "internetgateway" {
	vpc_id = aws_vpc.virtualprivatecloud.id
	tags = {
	Name = "internetgateway1"
}
}

resource "aws_route_table" "publicrt" {
	vpc_id = aws_vpc.virtualprivatecloud.id

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.internetgateway.id
}
	tags = {
	Name = "publicrt1"
}
}

resource "aws_route_table_association" "publicrtassociation" {
	subnet_id = aws_subnet.publicsubnet.id
	route_table_id = aws_route_table.publicrt.id
}

resource "aws_key_pair" "key" {
	key_name = "key1"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDnEQs70K39iUgFOJBPg+TfazlwqfvhW4BlUseJgB3neZK2MUim2f+NOvGqbvScv5Mz5+hxAwqApgKjaXGNviG0y8WVxzqnNvxFR56b5kQI9SiolLFbHqeSjfrcIxRctZntlChRTLf9S+6efz2PMgs7JwRpBPw/7Ogn/D5rsNdChqoOY6fApddLYdj36bd35l5eKgDmr4Z91CqZ4B5UbM5RHApMTjZ2mOzpxFxAcymS3qrbRlVlTVFfNV9Qv5m826WlY7boVnr7y9y77TVD+iNHYHRIosQ1cY605d4OwmbQUtohpD9Kyxtg3qK40T2/9GBN3Av++rsTq8JOptEqvECNE/8uqzNXsK7VJYuxuinoxRN/uIDVTcxm7UPXW9LDmn9fkQVtv5F9yaaSjEu5tPOhrCgb17/o3PUED8dDNCdb0mvnFpuAr4Dfusrit/m23Tg6QLw9fiUSFCMoRMk0KLvbQXSR2amTB7pxWbwvQJOCuajmTDUY34szwZ2PGjnkPuU= ubuntu@ip-172-31-85-180"
}

resource "aws_instance" "instance" {
	ami = "ami-0c7217cdde317cfec"
	instance_type = "t2.micro"
	subnet_id = aws_subnet.publicsubnet.id
	vpc_security_group_ids = [aws_security_group.securitygroup.id]
	key_name = "key1"
	tags = {
	Name = "instance-web"
}
}

resource "aws_instance" "dbinstance" {
        ami = "ami-0c7217cdde317cfec"
        instance_type = "t2.micro"
        subnet_id = aws_subnet.privatesubnet.id
        vpc_security_group_ids = [aws_security_group.securitygroup.id]
        key_name = "key1"
        tags = {
        Name = "instance-db"
}
}

resource "aws_eip" "publicip" {
	instance = aws_instance.instance.id
	vpc = true
}

resource "aws_eip" "publicipfornat" {
        vpc = true
}


resource "aws_nat_gateway" "natgateway" {
	allocation_id = aws_eip.publicipfornat.id
	subnet_id = aws_subnet.publicsubnet.id
}

resource "aws_route_table" "privatert" {
        vpc_id = aws_vpc.virtualprivatecloud.id

        route {
                cidr_block = "0.0.0.0/0"
                gateway_id = aws_nat_gateway.natgateway.id
}
        tags = {
        Name = "privatert1"
}
}

resource "aws_route_table_association" "privatertassociation" {
        subnet_id = aws_subnet.privatesubnet.id
        route_table_id = aws_route_table.privatert.id
}


