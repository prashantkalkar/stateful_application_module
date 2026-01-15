locals {
  node_id_to_node_map = {for node in var.nodes : node.node_id => node}
  node_id_to_node_files_map = {for node in var.node_files : node.node_id => node}
}

module "cluster_nodes" {
  for_each                             = local.node_id_to_node_map
  source                               = "./modules/node-module"
  app_name                             = var.app_name
  data_volume                          = merge(var.default_data_volume, each.value.node_data_disk)
  node_id                              = each.key
  node_instance_profile_id             = aws_iam_instance_profile.node_instance_profile.id
  node_ip                              = each.value.node_ip
  node_key_name                        = var.node_key_name
  node_subnet_id                       = each.value.node_subnet_id
  node_files_toupload                  = local.node_id_to_node_files_map[each.key].node_files_toupload
  node_config_script                   = var.node_config_script
  security_groups                      = var.security_groups
  node_image                           = each.value.node_image != null ? each.value.node_image : var.node_image
  jq_download_url                      = var.jq_download_url
  command_timeout_seconds              = var.command_timeout_seconds
  asg_lifecycle_hook_heartbeat_timeout = var.asg_lifecycle_hook_heartbeat_timeout
  instance_type                        = var.instance_type
  root_volume                          = var.root_volume
  http_put_response_hop_limit          = var.http_put_response_hop_limit
  skip_wait_for_cluster_health         = var.skip_wait_for_cluster_health
}

resource "null_resource" "roll_instances" {
  triggers = {
    node_template  = join(",", [for node_id, module_output in module.cluster_nodes: module_output.launch_template_version])
    asg_names      = join(" ", [for node_id, module_output in module.cluster_nodes: module_output.asg_name])
    rolling_script = filesha256("${path.module}/roll_cluster_instances.sh")
  }

  depends_on = [module.cluster_nodes]

  provisioner "local-exec" {
    command = "${path.module}/roll_cluster_instances.sh ${var.asg_inservice_timeout_in_mins}m ${self.triggers.asg_names}"
  }
}

