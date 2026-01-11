variable "project" {
  type = string
}

variable "domain" {
  type = string
}

variable "parent_zone_id" {
  type = string
}

variable "common_tags" {
  type = map(string)
}
