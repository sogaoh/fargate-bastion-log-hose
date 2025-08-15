variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}

variable "generic_role_name" {
  type    = string
  default = ""
}

variable "generic_policy_arns" {
  type    = list(string)
  default = []
}

variable "service" {
  type    = string
  default = ""
}

