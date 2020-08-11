resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "imagebuilder.${var.deployment_name}.vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_subnet" "us-east-2a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-2a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "imagebuilder.${var.deployment_name}.us-east-2a"
  }
}

resource "aws_subnet" "us-east-2b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-2b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "imagebuilder.${var.deployment_name}.us-east-2b"
  }
}

resource "aws_subnet" "us-east-2c" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = "us-east-2c"
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "imagebuilder.${var.deployment_name}.us-east-2c"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.us-east-2.s3"
  route_table_ids = [aws_vpc.main.main_route_table_id]

  tags = {
    Name = "imagebuilder.${var.deployment_name}.endpoint.s3"
  }
}

resource "aws_security_group" "manager" {
  name        = "imagebuilder.${var.deployment_name}.manager"
  description = "Manager tier security group"
  vpc_id      = aws_vpc.main.id

  // From: https://search.arin.net/rdap/?query=REDHAT-1
  ingress {
    description = "Ingress from Red Hat networks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "8.43.84.0/22",
      "38.145.32.0/19",
      "64.56.207.232/29",
      "66.187.224.0/20",
      "209.132.176.0/20"
    ]
  }

  // This obviously should be removed soon. 🤣
  ingress {
    description = "Ingress for Major"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "173.174.156.138/32"
    ]
  }

  ingress {
    description     = "Ingress from workers"
    from_port       = 8700
    to_port         = 8700
    protocol        = "tcp"
    security_groups = [aws_security_group.worker.id]
  }

  egress {
    description = "Allow outbound DNS (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound DNS (TCP)"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "imagebuilder.${var.deployment_name}.manager"
  }
}

resource "aws_security_group" "worker" {
  name        = "imagebuilder.${var.deployment_name}.worker"
  description = "Worker tier security group"
  vpc_id      = aws_vpc.main.id

  // From: https://search.arin.net/rdap/?query=REDHAT-1
  ingress {
    description = "Ingress from Red Hat networks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "8.43.84.0/22",
      "38.145.32.0/19",
      "64.56.207.232/29",
      "66.187.224.0/20",
      "209.132.176.0/20"
    ]
  }

  // This obviously should be removed soon. 🤣
  ingress {
    description = "Ingress for Major"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [
      "173.174.156.138/32"
    ]
  }

  egress {
    description = "Allow outbound DNS (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound DNS (TCP)"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "imagebuilder.${var.deployment_name}.manager"
  }
}