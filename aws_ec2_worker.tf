# AWS EC2: Worker
#
# Build workers in a spot fleet.

resource "aws_launch_template" "worker" {
  name          = "launch-template"
  image_id      = data.aws_ami.rhel8-cloudaccess.id
  instance_type = "t3.medium"
  key_name      = "personal_servers"
  iam_instance_profile {
    name = "imagebuilder-instance-roles"
  }
  user_data = base64encode(data.template_file.worker_user_data.rendered)

  vpc_security_group_ids = [
    aws_security_group.worker.id
  ]

  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 50
      volume_type = "standard"
    }
  }

  tags = {
    Name = "imagebuilder.${var.deployment_name}.worker"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "imagebuilder.${var.deployment_name}.worker"
    }
  }
  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "imagebuilder.${var.deployment_name}.worker"
    }
  }
}

resource "aws_spot_fleet_request" "worker" {
  allocation_strategy                 = "lowestPrice"
  fleet_type                          = "maintain"
  iam_fleet_role                      = "arn:aws:iam::438669297788:role/aws-ec2-spot-fleet-tagging-role"
  target_capacity                     = 5
  terminate_instances_with_expiration = true

  lifecycle {
    create_before_destroy = true
  }

  launch_template_config {
    launch_template_specification {
      id      = aws_launch_template.worker.id
      version = aws_launch_template.worker.latest_version
    }

    dynamic "overrides" {
      for_each = setproduct(var.worker_instance_types, aws_subnet.subnets)

      content {
        instance_type = overrides.value[0]
        subnet_id     = overrides.value[1].id
      }
    }
  }

  tags = {
    Name = "imagebuilder.${var.deployment_name}.worker"
  }
}

