variable "project" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "common_tags" {
  type = map(string)
}

variable "vpc_cidr_block" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "private_azs" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}
