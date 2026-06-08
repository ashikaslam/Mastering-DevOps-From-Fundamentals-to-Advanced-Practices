variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (update per region)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS - us-east-1
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair for SSH access"
  type        = string
}

variable "project_name" {
  description = "A tag prefix used to name all provisioned resources"
  type        = string
  default     = "module8-monitoring"
}
