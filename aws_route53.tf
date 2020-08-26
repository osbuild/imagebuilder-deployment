resource "aws_route53_record" "composer" {
  zone_id         = data.aws_route53_zone.builderinfra.zone_id
  name            = "composer.${var.deployment_name}.builderinfra.com"
  type            = "A"
  ttl             = "300"
  records         = [aws_instance.composer.private_ip]
  allow_overwrite = true
}