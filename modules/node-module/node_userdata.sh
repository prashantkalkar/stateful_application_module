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
REGION=${aws_region}
# shellcheck disable=SC2154
JQ_DOWNLOAD_URL=${jq_download_url}
# shellcheck disable=SC2154
COMMAND_TIMEOUT_SECS=${command_timeout_seconds}
# shellcheck disable=SC2154
MOUNT_VOLUME_SCRIPT_CONTENTS=${mount_volume_script_contents}
# shellcheck disable=SC2154
MOUNT_PATH=${mount_path}
# shellcheck disable=SC2154
FILE_SYSTEM_TYPE=${file_system_type}
# shellcheck disable=SC2154
COMMA_SEPARATED_MOUNT_PARAMS=${comma_separated_mount_params}
# shellcheck disable=SC2154
OWNER=${mount_path_owner_user}
# shellcheck disable=SC2154
GROUP=${mount_path_owner_group}
# shellcheck disable=SC2154
NODE_CONFIG_SCRIPT=${node_config_script}
# shellcheck disable=SC2154
NODE_INDEX=${node_index}
# shellcheck disable=SC2154
NODE_IP=${node_ip}

# upload files to node
# shellcheck disable=SC1083
%{ for file_details in node_files_toupload }
# shellcheck disable=SC2154
# shellcheck disable=SC2086
echo "${file_details.contents}" | base64 --decode > ${file_details.destination}
# shellcheck disable=SC1083
%{ endfor }

# get instance Id
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id)

# install Jq
curl -Lo jq "$JQ_DOWNLOAD_URL"
chmod +x jq
sudo mv jq /usr/local/bin/

echo "Waiting for EBS volume to be made available"
timeout "$COMMAND_TIMEOUT_SECS"s bash -c "until aws ec2 describe-volumes --volume-ids $VOLUME_ID --region $REGION | jq \".Volumes[].State\" | grep available; do sleep 20; done"

# Attach volume
aws ec2 attach-volume --device "$DEVICE_NAME" --instance-id "$INSTANCE_ID" --volume-id "$VOLUME_ID" --region "$REGION"

echo "Waiting for volume to be in-use"
timeout "$COMMAND_TIMEOUT_SECS"s bash -c "until aws ec2 describe-volumes --volume-ids $VOLUME_ID --region $REGION | jq \".Volumes[].State\" | grep in-use; do sleep 20; done"

# Mount volume
echo "$MOUNT_VOLUME_SCRIPT_CONTENTS" | base64 --decode > mount_volume.sh
chmod +x mount_volume.sh
./mount_volume.sh "$VOLUME_ID" "$MOUNT_PATH" "$FILE_SYSTEM_TYPE" "$COMMA_SEPARATED_MOUNT_PARAMS" "$OWNER" "$GROUP"

# Install required software.
echo "Calling the node configuration script"
echo "$NODE_CONFIG_SCRIPT" | base64 --decode > node_config_script.sh
chmod +x node_config_script.sh
source node_config_script.sh
configure_cluster_node "$NODE_INDEX" "$NODE_IP"

# Check cluster health as a whole
wait_for_healthy_cluster "$NODE_INDEX" "$NODE_IP"

# Update AWS ASG hook status to proceed.
aws autoscaling complete-lifecycle-action --lifecycle-action-result CONTINUE \
  --instance-id "$INSTANCE_ID" --lifecycle-hook-name "$ASG_HOOK_NAME" \
  --auto-scaling-group-name "$ASG_NAME" --region "$REGION"