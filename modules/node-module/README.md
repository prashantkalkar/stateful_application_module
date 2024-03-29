
### Notes

1. The EBS volume attach has to happen as part of user data. 
2. The user data also has to mount and format the disk (if format is required)
3. Also fstab configuration. 
4. Decide between cloud-init-config vs bash script execution. 

### Userdata steps

1. Attach volume (https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/attach-volume.html)
2. Mount volume (https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-using-volumes.html, https://cloudinit.readthedocs.io/en/latest/reference/modules.html#disk-setup)
3. Format volume if required. (https://cloudinit.readthedocs.io/en/latest/reference/modules.html#mounts) 
4. Install required software. 
5. Update AWS ASG hook status to proceed. (https://docs.aws.amazon.com/autoscaling/ec2/userguide/completing-lifecycle-hooks.html#completing-lifecycle-hooks-aws-cli) 

### Rotating script steps

Input => List of all ASGs. 

1. Check if cluster is healthy (or All ASGs are healthy - instances are InService)
2. Is instance refresh required? (Is the instance already replace. Any rotation required?)
3. If yes, terminate the existing ASG instance. 
4. Wait for new instance to be InService state.
5. Timeout and fail/exit, if instance did not change to InService within a time frame. 
6. If success, Repeat from 1st step for next ASG.

### Pending tasks

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.50.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.50.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.node_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_ebs_volume.node_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_launch_template.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_network_interface.node_network_interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_default_tags.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_subnet.node_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | n/a | `string` | n/a | yes |
| <a name="input_asg_lifecycle_hook_heartbeat_timeout"></a> [asg\_lifecycle\_hook\_heartbeat\_timeout](#input\_asg\_lifecycle\_hook\_heartbeat\_timeout) | n/a | `number` | n/a | yes |
| <a name="input_command_timeout_seconds"></a> [command\_timeout\_seconds](#input\_command\_timeout\_seconds) | n/a | `number` | n/a | yes |
| <a name="input_data_volume"></a> [data\_volume](#input\_data\_volume) | n/a | <pre>object({<br>    device_name            = string<br>    size_in_gibs           = number<br>    type                   = string<br>    iops                   = optional(number)<br>    throughput_mib_per_sec = optional(number)<br>    mount_path             = string<br>    file_system_type       = string<br>    mount_params           = list(string)<br>    mount_path_owner_user  = string<br>    mount_path_owner_group = string<br>    tags = optional(map(string), {})<br>  })</pre> | n/a | yes |
| <a name="input_http_put_response_hop_limit"></a> [http\_put\_response\_hop\_limit](#input\_http\_put\_response\_hop\_limit) | n/a | `number` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | n/a | yes |
| <a name="input_jq_download_url"></a> [jq\_download\_url](#input\_jq\_download\_url) | n/a | `string` | n/a | yes |
| <a name="input_node_config_script"></a> [node\_config\_script](#input\_node\_config\_script) | n/a | `string` | n/a | yes |
| <a name="input_node_files_toupload"></a> [node\_files\_toupload](#input\_node\_files\_toupload) | n/a | <pre>list(object({<br>    contents = string<br>    destination = string<br>  }))</pre> | n/a | yes |
| <a name="input_node_id"></a> [node\_id](#input\_node\_id) | n/a | `string` | n/a | yes |
| <a name="input_node_image"></a> [node\_image](#input\_node\_image) | n/a | `string` | n/a | yes |
| <a name="input_node_instance_profile_id"></a> [node\_instance\_profile\_id](#input\_node\_instance\_profile\_id) | n/a | `string` | n/a | yes |
| <a name="input_node_ip"></a> [node\_ip](#input\_node\_ip) | n/a | `string` | n/a | yes |
| <a name="input_node_key_name"></a> [node\_key\_name](#input\_node\_key\_name) | n/a | `string` | n/a | yes |
| <a name="input_node_subnet_id"></a> [node\_subnet\_id](#input\_node\_subnet\_id) | n/a | `string` | n/a | yes |
| <a name="input_root_volume"></a> [root\_volume](#input\_root\_volume) | n/a | <pre>object({<br>    device_name = string<br>    size_in_gibs = number<br>    type = string<br>  })</pre> | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_asg_name"></a> [asg\_name](#output\_asg\_name) | n/a |
| <a name="output_launch_template_version"></a> [launch\_template\_version](#output\_launch\_template\_version) | n/a |
| <a name="output_node_userdata_script"></a> [node\_userdata\_script](#output\_node\_userdata\_script) | n/a |
<!-- END_TF_DOCS -->