
resource "aws_launch_configuration" "ec2" {
	image_id = "ami-b5ed9ccd"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.ec2.id}"]

	lifecycle {
		create_before_destroy = true
	}

	user_data = <<-EOF
		#!/bin/bash
		echo "some stuff" >> index.html
		nohup busybox httpd -f -p "${var.server_port}" &
		EOF
}

resource "aws_autoscaling_group" "ec2_asg"{
	launch_configuration = "${aws_launch_configuration.ec2.id}"
	min_size = 2
	max_size = 10
 	availability_zones = [ "${data.aws_availability_zones.all.names}" ]

	load_balancers = ["${aws_elb.elb.name}"]
	health_check_type = "ELB"

	tag {
		key = "Name"
		value = "ec2_autoscaling_group"
		propagate_at_launch = true
	}
}

resource "aws_elb" "elb" {
	name = "terraform-elb-example"
	availability_zones = ["${data.aws_availability_zones.all.names}"]
	security_groups = ["${aws_security_group.elb.id}"]

	listener {
		lb_port = 80
		lb_protocol = "http"
		instance_port = "${var.server_port}"
		instance_protocol = "http"
	}

	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 2
		timeout = 3
		interval = 30
		target = "http:${var.server_port}/"
	}
}

resource "aws_security_group" "ec2" {
	name = "ec2 ingress"

	lifecycle {
		create_before_destroy = true
	}

	ingress {
		from_port = "${var.server_port}"
		to_port = "${var.server_port}"
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_security_group" "elb" {
	name = "elb ingress"

	lifecycle {
		create_before_destroy = true
	}

	ingress {
		from_port = "80"
		to_port = "80"
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
}
