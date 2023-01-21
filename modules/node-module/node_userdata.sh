#!/bin/bash

set -Exeuo pipefail

# shellcheck disable=SC2154
DEVICE_NAME=${device_name}
# shellcheck disable=SC2154
VOLUME_ID=${volume_id}
# shellcheck disable=SC2154
ASG_HOOK_NAME=${asg_hook_name}
# shellcheck disable=SC2154
ASG_NAME=${asg_name}
# shellcheck disable=SC2154
ENI_ID=${interface_id}
# shellcheck disable=SC2154
REGION=${aws_region}

# get instance Id
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)

# install Jq
curl -Lo jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq
sudo mv jq /usr/local/bin/

# Attach the ENI
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/best-practices-for-configuring-network-interfaces.html
# A warm or hot attach of an additional network interface might require you to manually bring up the second interface,
# configure the private IPv4 address, and modify the route table accordingly.
# Instances running Amazon Linux or Windows Server automatically recognize the warm or hot attach and configure themselves.
aws ec2 attach-network-interface --device-index 1 --instance-id "$INSTANCE_ID" --network-interface-id "$ENI_ID" --region "$REGION"

echo "Waiting for network-interface to be in-use"
timeout 200s bash -c "until aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $REGION | jq \".NetworkInterfaces[].Status\" | grep in-use ; do sleep 20; echo -n \".\"; done";

# Attach volume
aws ec2 attach-volume --device "$DEVICE_NAME" --instance-id "$INSTANCE_ID" --volume-id "$VOLUME_ID" --region "$REGION"

echo "Waiting for volume to be in-use"
aws ec2 wait volume-in-use --volume-ids "$VOLUME_ID" --region "$REGION"

# Mount volume

# Install required software.
echo "Installing required software"

# Update AWS ASG hook status to proceed.
aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE \
  --instance-id "$INSTANCE_ID" --lifecycle-hook-name "$ASG_HOOK_NAME" \
  --auto-scaling-group-name "$ASG_NAME" --region "$REGION"