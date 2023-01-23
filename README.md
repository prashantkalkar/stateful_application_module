# stateful_application_module
Terraform module implementation for managing stateful application on AWS modelled as immutable infrastructure.

### Usage
Note: Currently only Amazon Linux based AMI is supported. The setup installs additional ENI during instance userdata.
The current script depends on the Amazon Linux's ability to automatically configure the additional ENI.

(To be updated)
```terraform
module "cluster" {
  source = "git::git@github.com:prashantkalkar/stateful_application_module.git?ref=<version-git-tag>"
  app_name      = "kafka-test-setup"
  node_key_name = "my-keypair"
  nodes         = [
    {
      node_ip           = "<InstanceIPToBeAllocated>"
      node_subnet_id    = "<subnet_id>"
      availability_zone = "<zone_name>"
    },
    {
      node_ip           = "<InstanceIPToBeAllocated>"
      node_subnet_id    = "<subnet_id>"
      availability_zone = "<zone_name>"
    },
    {
      node_ip           = "<InstanceIPToBeAllocated>"
      node_subnet_id    = "<subnet_id>"
      availability_zone = "<zone_name>"
    }
  ]
  security_groups = [ ]
  node_image      = "<ami_id>"
}
```

### Why this module exists
TBA

### How the module works
TBA

### FAQs

**1. How do I debug the instance failure? (or My instance is stuck in Pending:Wait state, how do I recover?)**
Majority of instance failure will be due to userdata script. To debug the userdata script failure, ssh into the instance. The ssh can be done either through bastion (if bastion is being used) or AWS SSM session manager can be used to ssh into the instance.
The module code attach the AmazonSSMManagedInstanceCore permission to the instance for ssm based ssh to work.
Once logged into the instance, check out the /var/log/cloud-init-output.log fail for failure details.
```shell
sudo tail -200f /var/log/cloud-init-output.log
```
See the recovery FAQ for possible steps to recover from instance failure.

**2. The rolling script keeps waiting as one of my instance is not healthy. How do I recover?**
The rolling instance script is designed to fail fast. It's better to fail in case of errors for a single instance rather than updating multiple instances and failing multiple instances.
Multiple instance failure can cause the cluster level failure but generally a single node failure keeps the cluster in running state (as long as cluster quorum permits single node failure).
The rolling script will exit with failure when at least one instance is not InService status. This requires manual recovery.
You can possibly follow the following steps:
1. Make the appropriate configuration changes to terraform code that will update the ASG Launch template with the fix (this can be userdata changes or other changes).
2. Apply the changes, this will update the launch configurations but the rolling_update script will still wait for ASGs instances to be InService.
3. Complete ASG lifecycle hook as ABANDON to unblock the ASG to start a fresh instance.
```shell
aws autoscaling complete-lifecycle-action --lifecycle-action-result ABANDON \
  --instance-id "$INSTANCE_ID" --lifecycle-hook-name "$ASG_HOOK_NAME" \
  --auto-scaling-group-name "$ASG_NAME" --region "$REGION"
```
This should allow the instance to become InService. Rolling script should eventually detect that all instances are healthy and will proceed with rolling instances which are required to be changed.

**3. I have more than one instance in non InService state. What should I do?**
Ideally, the cluster should never get into the state where there are multiple instances failed. This will cause the cluster to be unavailable.
If the issue has occurred during the terraform rolling update script, then can also be a bug with the script. Please report the issue.
If the failure has occurred at runtime (not during terraform apply), then ideally instances should be automatically recovered unless infrastucture is manually changed to cause the failure during instance recovery.
Try to follow the FQA 1 and 2 to debug and recover the infrastructure to desired state.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.50.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.50.0 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_nodes"></a> [cluster\_nodes](#module\_cluster\_nodes) | ./modules/node-module | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.node_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_policy.node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.node_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.instance_userdata_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [null_resource.roll_instances](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.instance-assume-role-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | n/a | `string` | n/a | yes |
| <a name="input_asg_inservice_timeout_in_mins"></a> [asg\_inservice\_timeout\_in\_mins](#input\_asg\_inservice\_timeout\_in\_mins) | Timeout in mins which will be used by the rolling update script to wait for instances to be InService for an ASG | `number` | `10` | no |
| <a name="input_command_timeout_seconds"></a> [command\_timeout\_seconds](#input\_command\_timeout\_seconds) | The timeout that will be used by the userdata script to retry commands on failure. Keep it higher to allow manual recovery | `number` | `1800` | no |
| <a name="input_data_volume"></a> [data\_volume](#input\_data\_volume) | n/a | <pre>object({<br>    size_in_gibs = number<br>    type = string<br>    iops = optional(number)<br>    throughput_mib_per_sec = optional(number)<br>  })</pre> | n/a | yes |
| <a name="input_jq_download_url"></a> [jq\_download\_url](#input\_jq\_download\_url) | n/a | `string` | `"https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"` | no |
| <a name="input_node_image"></a> [node\_image](#input\_node\_image) | n/a | `string` | n/a | yes |
| <a name="input_node_key_name"></a> [node\_key\_name](#input\_node\_key\_name) | n/a | `string` | n/a | yes |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | n/a | <pre>list(object({<br>    node_ip = string<br>    node_subnet_id = string<br>  }))</pre> | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | `list(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
