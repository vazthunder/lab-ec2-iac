resource "aws_security_group" "bastion" {
  name          = "${var.project}-${var.env}-bastion"
  vpc_id        = var.vpc_id
  description   = "${var.project}-${var.env}-bastion"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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

resource "aws_iam_role" "bastion" {
  name = "${var.project}-${var.env}-bastion"
  
  assume_role_policy = jsonencode({
    Version: "2012-10-17"
    Statement: [{
      Action: "sts:AssumeRole"
      Principal: {
        Service: "ec2.amazonaws.com"
      }
      Effect: "Allow"
    }]
  })

  inline_policy {
    name = "${var.project}-${var.env}-bastion-policy"

    policy = jsonencode({
      Version: "2012-10-17"
      Statement: [
        {
          Action: [
            "s3:ListBucket",
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource: "*"
          Effect: "Allow"
        },
        {
          Action: "ecr:*"
          Resource: "*"
          Effect: "Allow"
        },
        {
          Action: [
            "codedeploy:CreateDeployment",
            "codedeploy:GetDeploymentConfig",
            "codedeploy:GetApplicationRevision",
            "codedeploy:RegisterApplicationRevision"
          ]
          Resource: "*"
          Effect: "Allow"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project}-${var.env}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
  ami                     = var.bastion_ami_id
  instance_type           = var.bastion_instance_type
  key_name                = var.key_name
  subnet_id               = var.subnet-public-a_id
  vpc_security_group_ids  = [ aws_security_group.bastion.id ]
  ebs_optimized           = true
  iam_instance_profile    = aws_iam_instance_profile.bastion.name
  user_data               = filebase64("${path.module}/user_data.sh")

  credit_specification {
    cpu_credits           = "standard"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.bastion_storage_size
    delete_on_termination = true
  }

  tags = {
    Name  = "${var.project}-${var.env}-bastion"
    Group = "${var.project}-${var.env}"
  }
}
