variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "project" {
  type = string
}

variable "eks_version" {
  type = string
}

variable "iam_role_eks" {
  type = string
}

variable "eks_nodes_role" {
  type = string
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_desired_size" {
  type = number
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}