resource "aws_route53_zone" "internal_zone" {
  name    = "imagebuilder.internal"
  comment = "imagebuilder internal DNS zone"
  vpc {
    vpc_id = aws_vpc.main.id
  }

  tags = {
    Name : "imagebuilder.${var.deployment_name}.zone"
  }
}

resource "aws_route53_record" "composer" {
  zone_id         = aws_route53_zone.internal_zone.zone_id
  name            = "composer.${var.deployment_name}.${var.aws_region}.imagebuilder.internal"
  type            = "A"
  ttl             = "300"
  records         = [aws_eip.composer.public_ip]
  allow_overwrite = true
}