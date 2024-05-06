variable "nodes" {
  type = set(object({
    node_id = string
    node_ip = string
    node_image = optional(string)
    node_subnet_id = string
    node_data_disk = optional(map(string), {})
  }))
  description = <<EOT
    node_id = node identifier (this is not a index and need not in any specific ordered).
    node_ip = IP address of the cluster node. This should be available within the subnet.
    node_image = image for node of the cluster node.
    node_subnet_id = Id of the subnet where node should be created.
    node_data_disk = override the default data disk configuration for the node. (follow the same schema of data disk).
  EOT
}

variable "node_files" {
  type = set(object({
    node_id = string
    node_files_toupload = optional(list(object({
      contents = string
      destination = string
    })), [])
  }))
  description = <<EOT
    node_id = node identifier (this is not a index and need not in any specific ordered).
    node_files_toupload = list of file to be uploaded per node. These can be cluster config files etc.
    node_files_toupload.contents = Base64 encoded contents of the file to be uploaded on the node.
    node_files_toupload.destination = File destination on the node. This will be the file path and name on the node. The file ownership should be changed by node_config_script.
  EOT
}

variable "default_data_volume" {
  type = object({
    device_name            = optional(string, "/dev/sdf")
    size_in_gibs           = number
    type                   = string
    iops                   = optional(number)
    throughput_mib_per_sec = optional(number)
    mount_path             = string
    file_system_type       = string
    mount_params           = optional(list(string), [])
    mount_path_owner_user  = string
    mount_path_owner_group = string
    tags                   = optional(map(string), {})
  })
  description = <<EOT
    This is default data volume configuration. This can be selectively overridden at node config level
      device_name            = "Device name for additional Data volume, select name as per https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/device_naming.html"
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

variable "node_config_script" {
  type = string
  description = <<EOT
  Base64 encoded node configuration shell script.
  Must include configure_cluster_node and wait_for_healthy_cluster function. Check documentation for more details about the contract
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

variable "instance_type" {
  type = string
}

variable "root_volume" {
  type = object({
    device_name = string
    size_in_gibs = number
    type = string
  })
  default = {
    device_name = "/dev/xvda"
    size_in_gibs = 16
    type = "gp3"
  }
}

variable "http_put_response_hop_limit" {
  type = number
  default = 1
}
