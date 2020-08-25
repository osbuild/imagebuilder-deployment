data "aws_ami" "rhel8-cloudaccess" {
  owners = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-8.2.1_HVM-20200803-x86_64-0-Access2-GP2"]
  }
}

data "aws_route53_zone" "buildinfra" {
  zone_id      = "Z032738211ODOXQOKZZWK"
  private_zone = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "template_file" "composer_user_data" {
  template = "${file("userdata/user_data.tpl")}"

  vars = {
    node_type         = "composer"
    node_hostname     = "composer.${var.deployment_name}.builderinfra.com"
    composer_hostname = "composer.${var.deployment_name}.builderinfra.com"

    rhn_registration_username = var.RHN_REGISTRATION_USERNAME
    rhn_registration_password = var.RHN_REGISTRATION_PASSWORD
  }
}

data "template_file" "worker_user_data" {
  template = "${file("userdata/user_data.tpl")}"

  vars = {
    node_type         = "worker"
    node_hostname     = "worker.${var.deployment_name}.builderinfra.com"
    composer_hostname = "composer.${var.deployment_name}.builderinfra.com"

    rhn_registration_username = var.RHN_REGISTRATION_USERNAME
    rhn_registration_password = var.RHN_REGISTRATION_PASSWORD
  }
}