variable "deployment_name" {
  description = "Name prepended to all AWS objects for the deployment"
  default     = "development"
}

variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-2"
}