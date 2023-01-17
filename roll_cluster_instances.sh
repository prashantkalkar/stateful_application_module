#!/bin/bash

set -Eeuo pipefail

asgWaitForCapacityTimeout=$1
shift
# https://github.com/koalaman/shellcheck/wiki/SC2124
asgNames=("$@")

# https://github.com/koalaman/shellcheck/wiki/SC2145
echo "Processing ASGs: $*"

# Check if cluster is healthy (or All ASGs are healthy - instances are InService)
# https://github.com/koalaman/shellcheck/wiki/SC2128
if ! aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "${asgNames[@]}" | jq ".AutoScalingGroups[].Instances[].LifecycleState" | grep -v InService
then
  echo "All instances are InService"
  # https://github.com/koalaman/shellcheck/wiki/SC2128
  for asgName in "${asgNames[@]}" ; do
    echo "Starting with instance rollout for ASG $asgName"
    asgLaunchTemplateVersion=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asgName" | jq -r ".AutoScalingGroups[].LaunchTemplate.Version")
    instanceTemplateVersion=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asgName" | jq -r ".AutoScalingGroups[].Instances[].LaunchTemplate.Version")

    if [ "$asgLaunchTemplateVersion" -ne "$instanceTemplateVersion" ]
    then
      echo "ASG Launch Template version $asgLaunchTemplateVersion does not match instance LT version $instanceTemplateVersion for ASG $asgName"
      echo "Terminating the instance to perform ASG rollout"
      instanceId=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name kafka-test-setup-node-00 | jq -r ".AutoScalingGroups[].Instances[0].InstanceId")

      aws autoscaling terminate-instance-in-auto-scaling-group --instance-id "$instanceId" --no-should-decrement-desired-capacity
      echo "Waiting for instance to be InService"
      timeout "$asgWaitForCapacityTimeout" bash -c "until aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name $asgName | jq \".AutoScalingGroups[].Instances[].LifecycleState\" | grep InService ; do sleep 10; echo -n \".\"; done";
      echo "Done"
    else
      echo "No instance rollout required for asg $asgName"
    fi
  done
fi
