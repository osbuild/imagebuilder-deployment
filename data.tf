data "terraform_remote_state" "network" {
  backend = "s3"
  backend "s3" {
    bucket = "imagebuilder-terraform"
    key    = "terraform.state"
    region = "us-east-2"
  }
}


data "aws_ami" "rhel8-cloudaccess" {
  owners = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-8.3.0_HVM_BETA-20200701-x86_64-2-Access2-GP2"]
  }
}

data "template_file" "worker_user_data" {
  template = "${file("userdata/worker.tpl")}"

  vars = {
    manager_hostname = "manager.${var.deployment_name}.${var.aws_region}.imagebuilder.internal"
    worker_hostname  = "worker.${var.deployment_name}.${var.aws_region}.imagebuilder.internal"
  }
}