variable "region" {
  type      = string
  sensitive = true
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}
