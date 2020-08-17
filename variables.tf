variable "deployment_name" {
  description = "Name prepended to all AWS objects for the deployment"
  default     = "development"
}

variable "aws_region" {
  description = "AWS region to launch servers"
  default     = "us-east-2"
}

variable "worker_instance_types" {
  description = "Instance types for workers"
  default = [
    "c5.large",
    "c5d.large",
    "c5a.large",
    "c5.xlarge",
    "c5d.xlarge",
    "c5a.xlarge"
  ]
}

variable "RHN_REGISTRATION_USERNAME" {
  description = "RHN Registration username"
}

variable "RHN_REGISTRATION_PASSWORD" {
  description = "RHN Registration password"
}