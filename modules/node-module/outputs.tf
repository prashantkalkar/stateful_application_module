output "launch_template_version" {
  value = aws_launch_template.node.latest_version
}

output "asg_name" {
  value = aws_autoscaling_group.node_asg.name
}

output "node_userdata_script" {
  value = local.userdata
}
