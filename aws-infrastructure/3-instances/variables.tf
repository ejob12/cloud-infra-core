variable "instance_count" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "environment" {
  type    = string
  default = "production"
}
