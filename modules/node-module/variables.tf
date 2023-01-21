variable "app_name" {
  type = string
}

variable "node_key_name" {
  type = string
}

variable "node_subnet_id" {
  type = string
}

variable "node_availability_zone" {
  type = string
}

variable "node_ip" {
  type = string
}

variable "node_index" {
  type = number
}

variable "data_volume" {
  type = object({
    size_in_gibs = number
    type = string
  })
}

variable "node_instance_profile_id" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "node_image" {
  type = string
}

variable "jq_download_url" {
  type = string
}

variable "command_timeout_seconds" {
  type = number
}
