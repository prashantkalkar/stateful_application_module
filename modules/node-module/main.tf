resource "aws_network_interface" "node_network_interface" {
  subnet_id       = var.node_subnet_id
  security_groups = var.security_groups
  private_ips     = [var.node_ip]

  tags = {
    Name = "${var.app_name}-interface-${var.node_id}"
  }
}

data "aws_default_tags" "current" {}

resource "aws_autoscaling_group" "node_asg" {
  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.latest_version
  }

  max_size = 1
  min_size = 1

  enabled_metrics = [
    "GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances",
    "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
  name                = local.asg_name
  availability_zones = [ data.aws_subnet.node_subnet.availability_zone ]

  initial_lifecycle_hook {
    name                 = local.asg_hook_name
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    default_result       = "ABANDON"
    # allow enough time for issue debug and recover
    heartbeat_timeout    = var.asg_lifecycle_hook_heartbeat_timeout
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.app_name}-node-${var.node_id}"
  }

  dynamic "tag" {
    for_each = data.aws_default_tags.current.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

data "aws_region" "current" {}

locals {
  asg_name = "${var.app_name}-node-${var.node_id}"
  userdata = templatefile("${path.module}/node_userdata.sh", {
    device_name                  = var.data_volume.device_name
    volume_id                    = aws_ebs_volume.node_data.id
    asg_hook_name                = local.asg_hook_name
    asg_name                     = local.asg_name
    aws_region                   = data.aws_region.current.name
    jq_download_url              = var.jq_download_url
    command_timeout_seconds      = var.command_timeout_seconds
    mount_volume_script_contents = filebase64("${path.module}/mount_volume.sh")
    mount_path                   = var.data_volume.mount_path
    file_system_type             = var.data_volume.file_system_type
    comma_separated_mount_params = join(",", var.data_volume.mount_params)
    mount_path_owner_user        = var.data_volume.mount_path_owner_user
    mount_path_owner_group       = var.data_volume.mount_path_owner_group
    node_files_toupload          = var.node_files_toupload
    node_config_script           = var.node_config_script
    node_id                      = var.node_id
    node_ip                      = var.node_ip
    skip_wait_for_cluster_health = var.skip_wait_for_cluster_health
  })
  asg_hook_name = "${var.app_name}-node-asg-hook"
}

resource "aws_launch_template" "node" {
  name          = "${var.app_name}-node-${var.node_id}"
  image_id      = var.node_image
  instance_type = var.instance_type

  monitoring {
    enabled = false
  }

  iam_instance_profile {
    name = var.node_instance_profile_id
  }

  network_interfaces {
    network_interface_id = aws_network_interface.node_network_interface.id
    device_index = 0
  }

  key_name = var.node_key_name

  block_device_mappings {
    device_name = var.root_volume.device_name # Root device as per AMI
    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = var.root_volume.size_in_gibs
      volume_type           = var.root_volume.type
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = var.http_put_response_hop_limit
    http_tokens                 = "required"
  }

  user_data = base64encode(local.userdata)

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.app_name}-node-${var.node_id}"
  }
}