resource "aws_security_group" "application" {
  name        = "${var.project}-${var.env}-${var.app_name}"
  vpc_id      = var.vpc_id
  description = "${var.project}-${var.env}-${var.app_name}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [ var.sg-bastion_id ]
  }

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [ var.sg-alb_id ]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_iam_role" "application" {
  name = "${var.project}-${var.env}-${var.app_name}"
  
  assume_role_policy = jsonencode({
    Version: "2012-10-17"
    Statement: [{
      Action: "sts:AssumeRole"
      Principal: {
        Service: "ec2.amazonaws.com"
      },
      Effect: "Allow"
    }]
  })

  inline_policy {
    name = "${var.project}-${var.env}-${var.app_name}"

    policy = jsonencode({
      Version: "2012-10-17"
      Statement: [
        {
          Action: [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer"
          ]
          Resource: "*"
          Effect: "Allow"
        },
        {
          Effect: "Allow"
          Action: [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents"
          ],
          Resource: "*"
        },
        {
          Effect: "Allow"
          Action: [
            "s3:GetObject",
            "s3:PutObject"
          ],
          Resource: "*"
        }
      ]    
    })
  }
}

resource "aws_iam_instance_profile" "application" {
  name = "${var.project}-${var.env}-${var.app_name}"
  role = aws_iam_role.application.name
}

resource "aws_launch_template" "application" {
  name                   = "${var.project}-${var.env}-${var.app_name}"
  image_id               = var.base_ami_id
  instance_type          = var.app_instance_type
  vpc_security_group_ids = [ aws_security_group.application.id ]
  key_name               = var.key_name
  ebs_optimized          = true
  user_data              = filebase64("${path.module}/user_data.sh")
  
  iam_instance_profile {
    arn = aws_iam_instance_profile.application.arn
  }

  credit_specification {
    cpu_credits = "standard"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = "gp3"
      volume_size           = var.app_storage_size
      delete_on_termination = true
    }
  }
}

resource "aws_autoscaling_group" "application" {
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = [ var.subnet-private-a_id, var.subnet-private-b_id ]
  target_group_arns         = [ aws_alb_target_group.application.arn ]
  min_size                  = var.app_min_size
  max_size                  = var.app_max_size
  desired_capacity          = var.app_desired_size

  launch_template {
    id      = aws_launch_template.application.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-${var.env}-${var.app_name}"
    propagate_at_launch = true
  }
  
  tag {
    key                 = "Group"
    value               = "${var.project}-${var.env}"
    propagate_at_launch = true
  }

  depends_on = [
    aws_alb_listener_rule.application, # Wait for target group to be attached to ALB first
  ]
}

resource "aws_alb_target_group" "application" {
  name_prefix = var.app_name
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 15
    matcher             = "200"
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener_rule" "application" {
  listener_arn = var.alb-listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.application.arn
  }

  condition {
    path_pattern {
      values = ["${var.app_path}*"]
    }
  }
}
