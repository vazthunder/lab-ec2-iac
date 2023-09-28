resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.env}-alb"
  vpc_id      = var.vpc_id
  description = "${var.project}-${var.env}-alb"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Group = "${var.project}-${var.env}"
  }
}

resource "aws_alb_listener" "http" {
  port              = 80
  protocol          = "HTTP"
  load_balancer_arn = aws_alb.main.arn

  default_action {
    type = "redirect"
    
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# resource "aws_alb_listener" "https" {
#   load_balancer_arn = aws_alb.main.arn
#   port              = 443
#   protocol          = "HTTPS"
#   certificate_arn   = var.certificate_arn

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       status_code  = "404"
#     }
#   }
# }

resource "aws_alb" "main" {
  name            = "${var.project}-${var.env}-alb"
  internal        = false
  security_groups = [ aws_security_group.alb.id ]
  subnets         = [ var.subnet-public-a_id, var.subnet-public-b_id ]
  enable_http2    = true

  tags = {
    Group = "${var.project}-${var.env}"
  }
}
