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
# shellcheck disable=SC2154
JQ_DOWNLOAD_URL=${jq_download_url}
# shellcheck disable=SC2154
COMMAND_TIMEOUT_SECS=${command_timeout_seconds}

# get instance Id
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)

# install Jq
curl -Lo jq "$JQ_DOWNLOAD_URL"
chmod +x jq
sudo mv jq /usr/local/bin/

echo "Waiting for network interface and EBS volume to be made available"
timeout "$COMMAND_TIMEOUT_SECS"s bash -c "until aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $REGION | jq \".NetworkInterfaces[].Status\" | grep available ; do sleep 20; echo -n \".\"; done";
timeout "$COMMAND_TIMEOUT_SECS"s bash -c "until aws ec2 describe-volumes --volume-ids $VOLUME_ID --region $REGION | jq \".Volumes[].State\" | grep available; do sleep 20; done"

# Attach the ENI
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/best-practices-for-configuring-network-interfaces.html
# A warm or hot attach of an additional network interface might require you to manually bring up the second interface,
# configure the private IPv4 address, and modify the route table accordingly.
# Instances running Amazon Linux or Windows Server automatically recognize the warm or hot attach and configure themselves.
aws ec2 attach-network-interface --device-index 1 --instance-id "$INSTANCE_ID" --network-interface-id "$ENI_ID" --region "$REGION"

echo "Waiting for network-interface to be in-use"
timeout "$COMMAND_TIMEOUT_SECS"s bash -c "until aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $REGION | jq \".NetworkInterfaces[].Status\" | grep in-use ; do sleep 20; echo -n \".\"; done";

# Attach volume
aws ec2 attach-volume --device "$DEVICE_NAME" --instance-id "$INSTANCE_ID" --volume-id "$VOLUME_ID" --region "$REGION"

echo "Waiting for volume to be in-use"
timeout "$COMMAND_TIMEOUT_SECS"s bash -c "until aws ec2 describe-volumes --volume-ids $VOLUME_ID --region $REGION | jq \".Volumes[].State\" | grep in-use; do sleep 20; done"

# Mount volume

# Install required software.
echo "Installing required software"

# Update AWS ASG hook status to proceed.
aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE \
  --instance-id "$INSTANCE_ID" --lifecycle-hook-name "$ASG_HOOK_NAME" \
  --auto-scaling-group-name "$ASG_NAME" --region "$REGION"