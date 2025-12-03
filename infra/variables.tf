variable "project" {
  type    = string
  default = "eks-game"
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "domain" {
  type    = string
  default = "hamsa-ahmed.co.uk"
}

variable "parent_zone_id" {
  type    = string
  default = "Z07385433QNXDZZ6RBE0E"
}

variable "eks_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "environment" {
  type    = string
  default = "dev"
}


