variable "nodes" {
  type = list(object({
    node_ip = string
    node_subnet_id = string
  }))
}

variable "data_volume" {
  type = object({
    size_in_gibs = number
    type = string
    iops = optional(number)
    throughput_mib_per_sec = optional(number)
  })
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
  description = "Timeout in mins which will be used by the rolling update script to wait for instances to be InService for an ASG"
}

variable "jq_download_url" {
  type = string
  default = "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
}

variable "command_timeout_seconds" {
  type = number
  default = 1800
  description = "The timeout that will be used by the userdata script to retry commands on failure. Keep it higher to allow manual recovery"
}
