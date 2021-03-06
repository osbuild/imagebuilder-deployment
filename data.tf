data "aws_ami" "rhel8-cloudaccess" {
  owners = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-8.2.1_HVM-20200803-x86_64-0-Access2-GP2"]
  }
}

data "aws_route53_zone" "builderinfra" {
  zone_id      = "Z032738211ODOXQOKZZWK"
  private_zone = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "template_file" "composer_user_data" {
  template = "${file("userdata/set_variables.template")}"

  vars = {
    node_type         = "composer"
    node_hostname     = "composer.${var.deployment_name}.builderinfra.com"
    composer_hostname = "composer.${var.deployment_name}.builderinfra.com"

    rhn_registration_username = var.RHN_REGISTRATION_USERNAME
    rhn_registration_password = var.RHN_REGISTRATION_PASSWORD

    # 💣 Split off most of the setup script to avoid shenanigans with
    # Terraform's template interpretation that destroys Bash variables.
    # https://github.com/hashicorp/terraform/issues/15933
    setup_script = "${file("userdata/setup.sh")}"
  }
}

data "template_file" "worker_user_data" {
  template = "${file("userdata/set_variables.template")}"

  vars = {
    node_type         = "worker"
    node_hostname     = "worker.${var.deployment_name}.builderinfra.com"
    composer_hostname = "composer.${var.deployment_name}.builderinfra.com"

    rhn_registration_username = var.RHN_REGISTRATION_USERNAME
    rhn_registration_password = var.RHN_REGISTRATION_PASSWORD

    # 💣 Split off most of the setup script to avoid shenanigans with
    # Terraform's template interpretation that destroys Bash variables.
    # https://github.com/hashicorp/terraform/issues/15933
    setup_script = "${file("userdata/setup.sh")}"
  }
}