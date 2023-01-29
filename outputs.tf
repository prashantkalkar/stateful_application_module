output "node_iam_role_name" {
  value = aws_iam_role.node_role.name
}

output "asg_names" {
  value = module.cluster_nodes[*].asg_name
}