variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "cert_manager_role_arn" {
  type = string
}

variable "external_dns_role_arn" {
  type = string
}

variable "domain" {
  type = string
}