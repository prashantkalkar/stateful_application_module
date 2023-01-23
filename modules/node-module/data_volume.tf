data "aws_subnet" "node_subnet" {
  id = var.node_subnet_id
}

#tfsec:ignore:aws-ec2-volume-encryption-customer-key
resource "aws_ebs_volume" "node_data" {
  #checkov:skip=CKV_AWS_189:Not using CMK for now.
  availability_zone = data.aws_subnet.node_subnet.availability_zone
  size              = var.data_volume.size_in_gibs
  type              = var.data_volume.type
  iops              = var.data_volume.iops
  throughput        = var.data_volume.throughput_mib_per_sec
  encrypted         = true

  tags = {
    Name = "${var.app_name}-data-${format("%02d", var.node_index)}"
  }
}