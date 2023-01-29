module "cluster_nodes" {
  count                                = length(var.nodes)
  source                               = "./modules/node-module"
  app_name                             = var.app_name
  data_volume                          = var.data_volume
  node_index                           = count.index
  node_instance_profile_id             = aws_iam_instance_profile.node_instance_profile.id
  node_ip                              = var.nodes[count.index].node_ip
  node_key_name                        = var.node_key_name
  node_subnet_id                       = var.nodes[count.index].node_subnet_id
  node_files_toupload                  = var.nodes[count.index].node_files_toupload
  node_config_script                   = var.node_config_script
  security_groups                      = var.security_groups
  node_image                           = var.node_image
  jq_download_url                      = var.jq_download_url
  command_timeout_seconds              = var.command_timeout_seconds
  asg_lifecycle_hook_heartbeat_timeout = var.asg_lifecycle_hook_heartbeat_timeout
  instance_type                        = var.instance_type
  root_volume                          = var.root_volume
}

resource "null_resource" "roll_instances" {
  triggers = {
    node_template  = join(",", module.cluster_nodes[*].launch_template_version)
    asg_names      = join(" ", module.cluster_nodes[*].asg_name)
    rolling_script = filesha256("${path.module}/roll_cluster_instances.sh")
  }

  depends_on = [module.cluster_nodes]

  provisioner "local-exec" {
    command = "${path.module}/roll_cluster_instances.sh ${var.asg_inservice_timeout_in_mins}m ${self.triggers.asg_names}"
  }
}

