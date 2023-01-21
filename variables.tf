variable "nodes" {
  type = list(object({
    node_ip = string
    node_subnet_id = string
    availability_zone = string
  }))
}

variable "node_key_name" {
  type = string
}

variable "app_name" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "node_image" {
  type = string
}

variable "asg_inservice_timeout_in_mins" {
  type = number
  default = 10
}
