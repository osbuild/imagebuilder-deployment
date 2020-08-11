data "aws_ami" "rhel8-cloudaccess" {
  owners = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-8.3.0_HVM_BETA-20200701-x86_64-2-Access2-GP2"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "template_file" "composer_user_data" {
  template = "${file("userdata/composer.tpl")}"

  vars = {
    composer_hostname = "composer.${var.deployment_name}.${var.aws_region}.imagebuilder.internal"
  }
}

data "template_file" "worker_user_data" {
  template = "${file("userdata/worker.tpl")}"

  vars = {
    composer_hostname = "composer.${var.deployment_name}.${var.aws_region}.imagebuilder.internal"
    worker_hostname   = "worker.${var.deployment_name}.${var.aws_region}.imagebuilder.internal"
  }
}