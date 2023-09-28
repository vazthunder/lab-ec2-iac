resource "aws_iam_role" "codedeploy" {
  name = "${var.project}-${var.env}-${var.app_name}-codedeploy"
  
  assume_role_policy = jsonencode({
    Version: "2012-10-17"
    Statement: [{
      Action: "sts:AssumeRole"
      Principal: {
        Service: "codedeploy.amazonaws.com"
      }
      Effect: "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy-service-role" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_codedeploy_app" "application" {
  name             = "${var.project}-${var.env}-${var.app_name}"
  compute_platform = "Server"
}

resource "aws_codedeploy_deployment_group" "application" {
  app_name               = aws_codedeploy_app.application.name
  deployment_group_name  = "${var.project}-${var.env}-${var.app_name}"
  service_role_arn       = aws_iam_role.codedeploy.arn
  autoscaling_groups     = [ aws_autoscaling_group.application.name ]
  deployment_config_name = "CodeDeployDefault.OneAtATime"

  deployment_style {
    deployment_type   = "IN_PLACE"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  load_balancer_info {
    target_group_info {
      name = aws_alb_target_group.application.name
    }
  }
}
