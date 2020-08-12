# AWS EC2: Composer
#
# Build a single instance of osbuild-composer with an attached EBS volume and
# an elastic IP address.

resource "aws_ebs_volume" "composer" {
  availability_zone = "us-east-2a"
  size              = 500
  type              = "standard"

  tags = {
    Name = "imagebuilder.${var.deployment_name}.composer"
  }
}

resource "aws_volume_attachment" "composer" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.composer.id
  instance_id = aws_instance.composer.id
}

resource "aws_instance" "composer" {
  ami                  = data.aws_ami.rhel8-cloudaccess.id
  instance_type        = "t3.small"
  iam_instance_profile = "imagebuilder-instance-roles"
  key_name             = "personal_servers"
  subnet_id            = aws_subnet.subnets[0].id
  vpc_security_group_ids = [
    aws_security_group.composer.id
  ]
  user_data = base64encode(data.template_file.composer_user_data.rendered)

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "standard"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = false
  }

  tags = {
    Name = "imagebuilder.${var.deployment_name}.composer"
  }
}

resource "aws_eip" "composer" {
  instance = aws_instance.composer.id
  vpc      = true
}