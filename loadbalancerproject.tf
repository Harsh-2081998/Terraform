provider "aws" {
        region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
        cidr_block = var.cidr
}

resource "aws_subnet" "mysubnet1" {
        vpc_id = aws_vpc.myvpc.id
        cidr_block = "10.0.1.0/24"
        availability_zone = "us-east-1a"
        map_public_ip_on_launch = true

}

resource "aws_subnet" "mysubnet2" {
        vpc_id = aws_vpc.myvpc.id
        cidr_block = "10.0.2.0/24"
        availability_zone = "us-east-1b"
        map_public_ip_on_launch = true

}

resource "aws_internet_gateway" "myigw" {
        vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "myrt1" {
        vpc_id = aws_vpc.myvpc.id
        route {
                cidr_block = "0.0.0.0/0"
                gateway_id = aws_internet_gateway.myigw.id
}
}

resource "aws_route_table_association" "myrtassociation1" {
        subnet_id = aws_subnet.mysubnet1.id
        route_table_id = aws_route_table.myrt1.id
}

resource "aws_route_table_association" "myrtassociation2" {
        subnet_id = aws_subnet.mysubnet2.id
        route_table_id = aws_route_table.myrt1.id
resource "aws_security_group" "mysg1" {
        name_prefix = "websg"
        vpc_id = aws_vpc.myvpc.id

        ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
}
        ingress {
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
        Name = "websg"
}
}
resource "aws_s3_bucket" "s3bucket" {
        bucket = "19bucket20"
}

resource "aws_s3_bucket_public_access_block" "s3access" {
  bucket = aws_s3_bucket.s3bucket.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_instance" "webserver1" {
        ami = "ami-0c7217cdde317cfec"
        instance_type = "t2.micro"
        key_name = "ec2_keypair"
        vpc_security_group_ids = [aws_security_group.mysg1.id]
        subnet_id = aws_subnet.mysubnet1.id
        user_data = base64encode(file("userdata.sh"))
}

resource "aws_instance" "webserver2" {
        ami = "ami-0c7217cdde317cfec"
        instance_type = "t2.micro"
        key_name = "ec2_keypair"
        vpc_security_group_ids = [aws_security_group.mysg1.id]
        subnet_id = aws_subnet.mysubnet2.id
        user_data = base64encode(file("userdata1.sh"))
}

resource "aws_lb" "myalb" {
	name = "myalb"
	internal = false
	load_balancer_type = "application"

	security_groups = [aws_security_group.mysg1.id]
	subnets = [aws_subnet.mysubnet1.id, aws_subnet.mysubnet2.id]
}

resource "aws_lb_target_group" "tg" {
	name = "mytg"
	port = 80
	protocol = "HTTP"
	vpc_id = aws_vpc.myvpc.id

	health_check {
		path = "/"
		port = "traffic-port"
}
}

resource "aws_lb_target_group_attachment" "lbattach1" {
	target_group_arn = aws_lb_target_group.tg.arn
	target_id = aws_instance.webserver1.id
	port = 80
}

resource "aws_lb_target_group_attachment" "lbattach2" {
	target_group_arn = aws_lb_target_group.tg.arn
	target_id = aws_instance.webserver2.id
	port = 80
}

resource "aws_lb_listener" "listener" {
	load_balancer_arn = aws_lb.myalb.arn
	port = 80
	protocol = "HTTP"
	
	default_action {
		target_group_arn = aws_lb_target_group.tg.arn
		type = "forward"
}
}
