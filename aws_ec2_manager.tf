resource "aws_ebs_volume" "manager" {
  availability_zone = "us-east-2a"
  size              = 50
  type              = "standard"

  tags = {
    Name = "imagebuilder.${var.deployment_name}.manager"
  }
}

resource "aws_volume_attachment" "manager" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.manager.id
  instance_id = aws_instance.manager.id
}

data "template_file" "manager_user_data" {
  template = "${file("userdata/manager.tpl")}"

  vars = {
    manager_hostname = "manager.${var.deployment_name}.${var.aws_region}.imagebuilder.internal"
  }
}

resource "aws_instance" "manager" {
  ami           = data.aws_ami.rhel8-cloudaccess.id
  instance_type = "t3.small"
  iam_instance_profile {
    name = "imagebuilder-instance-roles"
  }
  key_name  = "personal_servers"
  subnet_id = aws_subnet.us-east-2a.id
  vpc_security_group_ids = [
    aws_security_group.manager.id,
    "sg-0bff440d29aa6992b"
  ]
  user_data = base64encode(data.template_file.manager_user_data.rendered)

  root_block_device {
    volume_type           = "standard"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = false
  }

  tags = {
    Name = "imagebuilder.${var.deployment_name}.manager"
  }
}

resource "aws_eip" "manager" {
  instance = aws_instance.manager.id
  vpc      = true
}