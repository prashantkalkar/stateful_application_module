resource "aws_iam_instance_profile" "node_instance_profile" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.node_role.name
}

resource "aws_iam_role" "node_role" {
  name = "${var.app_name}-role"
  assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "instance_userdata_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = aws_iam_policy.node_policy.arn
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "node_policy" {
  name = "${var.app_name}-node-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:AttachVolume",
          "ec2:AttachNetworkInterface",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:RecordLifecycleActionHeartbeat"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*",
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:volume/*",
          "arn:aws:autoscaling:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:autoScalingGroup:*"
        ]
      },
      {
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVolumes",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}