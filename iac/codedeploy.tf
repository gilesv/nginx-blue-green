resource "aws_codedeploy_app" "nginx" {
  compute_platform = "Server"
  name             = "nginx-proxy-cache"
}

resource "aws_iam_role" "codedeploy_role" {
  name                  = "CodeDeployServiceRole"
  assume_role_policy    = jsonencode(
    {
      Statement = [
        {
          Action    = "sts:AssumeRole"
          Effect    = "Allow"
          Principal = {
            Service = "codedeploy.amazonaws.com"
          }
          Sid       = ""
        },
      ]
      Version   = "2012-10-17"
    }
  )
}

resource "aws_codedeploy_deployment_group" "nginx-group2" {
    app_name               = aws_codedeploy_app.nginx.name
    deployment_group_name  = "nginx-dg2"
    autoscaling_groups     = [
        aws_autoscaling_group.nginx_asg.name
    ]
    deployment_config_name = "CodeDeployDefault.OneAtATime"
    service_role_arn       = aws_iam_role.codedeploy_role.arn

    auto_rollback_configuration {
        enabled = true
        events  = [
            "DEPLOYMENT_FAILURE",
            "DEPLOYMENT_STOP_ON_ALARM",
        ]
    }

    blue_green_deployment_config {
        deployment_ready_option {
            action_on_timeout    = "CONTINUE_DEPLOYMENT"
            wait_time_in_minutes = 0
        }
        green_fleet_provisioning_option {
            action = "COPY_AUTO_SCALING_GROUP"
        }
        terminate_blue_instances_on_deployment_success {
            action                           = "TERMINATE"
            termination_wait_time_in_minutes = 5
        }
    }

    deployment_style {
        deployment_option = "WITH_TRAFFIC_CONTROL"
        deployment_type   = "BLUE_GREEN"
    }

    load_balancer_info {
        target_group_info {
            name = aws_lb_target_group.nginx_tg.name
        }
    }
}
