variable "nodes" {
  type = list(object({
    node_ip = string
    node_subnet_id = string
  }))
}

variable "data_volume" {
  type = object({
    size_in_gibs           = number
    type                   = string
    iops                   = optional(number)
    throughput_mib_per_sec = optional(number)
    mount_path             = string
    file_system_type       = string
    mount_params           = optional(list(string), [])
    mount_path_owner_user  = string
    mount_path_owner_group = string
  })
  description = <<EOT
    type                   = "EBS volume type e.g. gp2, gp3 etc"
    iops                   = "Only valid for type gp3"
    throughput_mib_per_sec = "only valid for type gp3"
    mount_path             = "path where to mount the data volume"
    file_system_type       = "File system to use to format the volume. eg. ext4 or xfs. This is used only initial time. Later changes will be ignored"
    mount_params           = "Parameters to be used while mounting the volume eg. noatime etc. Optional, empty if not provided"
    mount_path_owner_user  = "OS user that should own volume mount path will be used for chown"
    mount_path_owner_group = "OS group that should own the volume mount path, will be used for chown"
  EOT
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

variable "asg_lifecycle_hook_heartbeat_timeout" {
  type = number
  default = 3600
  description = "Timeout for ASG initial lifecycle hook. This is used only during ASG creation, subsequent value changes are not handled by terraform (has to be updated manually)"
}

