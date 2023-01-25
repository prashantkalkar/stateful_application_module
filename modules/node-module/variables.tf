variable "app_name" {
  type = string
}

variable "node_key_name" {
  type = string
}

variable "node_subnet_id" {
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
    size_in_gibs           = number
    type                   = string
    iops                   = optional(number)
    throughput_mib_per_sec = optional(number)
    mount_path             = string
    file_system_type       = string
    mount_params           = list(string)
    mount_path_owner_user  = string
    mount_path_owner_group = string
  })
}

variable "node_files_toupload" {
  type = list(object({
    contents = string
    destination = string
  }))
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

variable "asg_lifecycle_hook_heartbeat_timeout" {
  type = number
}
