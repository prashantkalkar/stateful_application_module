## Unreleased

## v0.8.0

Changes:
* Added support for S3 URL-based node configuration scripts - Added `node_config_script_s3_url` variable to support downloading configuration scripts from S3. This is useful when scripts exceed AWS userdata 16KB limit. The implementation includes:
  - S3 URL takes precedence if provided
  - Automatic fallback to embedded `node_config_script` if S3 download fails or returns empty file
  - Both variables are now optional (with `default = null`), but at least one must be provided
  - Runtime validation ensures downloaded script is not null or empty before proceeding
  - Fail-fast behavior with clear error messages if neither option provides a valid script
  - Backward compatible - existing code using `node_config_script` continues to work without changes

## v0.7.0

Changes:
* Mount script file system extend steps - Added step to extend the file system on expansion of the underline EBS volume.

## v0.6.0

Upgrade notes:
* Renamed the `data_volume` variable to `default_data_volume`. The data disk config now represent default disk configuration. 
  This is overridable at node level if required.
  For existing code change as follows:
    ```terraform
      data_volume = {
        # ...
      }
    ```
  To new code
    ```terraform
      default_data_volume = {
        # ...
      }
    ```
Breaking Changes:
* Renamed the data_volume variable as default_data_volume. The new configuration represent default data disk config which will be used by all the nodes. 
  This can be overridden at node level by providing selectively different values for the values. (See the input variable documents)

Full Changelog: [v0.5.0...v0.6.0](https://github.com/prashantkalkar/stateful_application_module/compare/v0.5.0...v0.6.0)

## v0.5.0

Upgrade notes:
* node_files argument added: Terraform plan was failing when sensitive files are used for node uploads. This was happening due to node usage in the for_each attribute. Terraform plan fails if sensitive data is used for either keys or values for `for_each` property (see [issue#16](https://github.com/prashantkalkar/stateful_application_module/issues/16)).  
  For existing code change as follows:
    ```terraform
      nodes         = [{
        node_ip             = "172.31.140.18"
        node_id             = "00"
        node_subnet_id      = data.aws_subnet.subnet1.id
        node_files_toupload = []
      }]
    ```
  To new code
    ```terraform
      nodes         = [{
        node_ip             = "172.31.140.18"
        node_id             = "00"
        node_subnet_id      = data.aws_subnet.subnet1.id
      }]
      node_files    = [{
        node_id             = "00"
        node_files_toupload = []
      }]
    ```

Breaking Changes: 
* added node_files argument: Terraform plan was failing when sensitive files are used for node uploads. This was happening due to node usage in the for_each attribute. Terraform plan fails if sensitive data is used for either keys or values for `for_each` property (see [issue#16](https://github.com/prashantkalkar/stateful_application_module/issues/16))  by @ganesh-arkalgud in [#17](https://github.com/prashantkalkar/stateful_application_module/pull/17)

Full Changelog: [v0.4.0...v0.5.0](https://github.com/prashantkalkar/stateful_application_module/compare/v0.4.0...v0.5.0)

## v0.4.0

Upgrade notes:
* node_id argument change: The nodes array now require a node_id parameter. This id is used to identify and name the node in the cluster and for naming the AWS resources. 
    For existing code change as follows:
    ```terraform
      nodes         = [{
        node_ip             = "172.31.140.18"
        node_subnet_id      = data.aws_subnet.subnet1.id
        node_files_toupload = []
      }]
    ```
    To new code
    ```terraform
      nodes         = [{
        node_ip = "172.31.140.18"
        node_id = "00"
        node_subnet_id      = data.aws_subnet.subnet1.id
        node_files_toupload = []
      }]
    ```
    Note, the node_id can be any string but if you want to retain the node names use the 2 digit node_id (eg. 00, 01, 05, 10 etc) during the upgrades.

* Resource changes: Since terraform state resources are not tracked by node index and instead are tracked with node_id, the resource addresses are now changed. 
    Terraform can not identify this change and treats the old and new resources as different resources. This will cause the infrastructure to be destroyed and re-created.
    All we need is to move the resources to new address. The terraform move block should help with this. 
    ```terraform
    moved {
      from = module.your_module_name.module.cluster_nodes[0]
      to   = module.your_module_name.module.cluster_nodes["00"]
    }
    
    moved {
      from = module.your_module_name.module.cluster_nodes[1]
      to   = module.your_module_name.module.cluster_nodes["01"]
    }
    ```
    Here, the older index based address is moved now to newer node_id based address for the resource. One move block will be required per node.       
* Contract change in node_config_script:
    The node_config_script will now receive node_id instead of node_index. The node_config_script will likely change as follows:
    ```shell
    # old node_config_script callback functions
    function configure_cluster_node() {
      local node_index=$1
      local node_ip=$2
      # rest of the code to configure the cluster. 
    }
    
    function wait_for_healthy_cluster() {
      local node_index=$1
      local node_ip=$2
      # rest of the code related to waiting for cluster to be healthy 
    }
    ```
    ```shell
    # new node_config_script callback functions
    function configure_cluster_node() {
      local node_id=$1
      local node_ip=$2
      # rest of the code to configure the cluster. 
    }
    
    function wait_for_healthy_cluster() {
      local node_id=$1
      local node_ip=$2
      # rest of the code related to waiting for cluster to be healthy 
    }
    ```
    Both the above functions should expect the first argument as node_id and not node_index. 
    NOTE - older value when index was used would be 0 for index 0 (number) but now if the id is 00 then that is what will be received (string).
* http_put_response_hop_limit argument change: A new variable with default value = 1 is added. The older value for this is 3. If you want to retain the older value
    pass in the `http_put_response_hop_limit=3` for module call. http_put_response_hop_limit=1 is generally consider a good practice. 
* TF plan: Expect following resources to change per node
  - Node launch template - This will change due to script changes as well as http_put_response_hop_limit changes (if not overriden to old value of 3)
  - Node ASG - due to changes in launch template.
  - roll_instances script - due to changes in the launch template.
  - move changes - Most other resources should just show move changes (due to move blocks above).

Breaking Changes:
* Update to move away from index based node ordering. by @prashantkalkar in [#12](https://github.com/prashantkalkar/stateful_application_module/pull/12)
* Added http_put_response_hop_limit as a module parameter with default value = 1. by @prashantkalkar in [#12](https://github.com/prashantkalkar/stateful_application_module/pull/12)

Changes:
- Added the output variable for the userdata script. This allows the caller to add the script to TF output variable.  
  Any future changes in this variable will be highlighted during terraform plan allowing the user to see what is being changed in the instance.
  by @prashantkalkar in [#13](https://github.com/prashantkalkar/stateful_application_module/pull/13)


## v0.3.0

Changes:
* added optional tags support for node volume by @vaibhavsahaj in [#10](https://github.com/prashantkalkar/stateful_application_module/pull/10)
* Updated documentation as per new variables for the modules. by @prashantkalkar in [#11](https://github.com/prashantkalkar/stateful_application_module/pull/11)

Full Changelog: [v0.2.0...v0.3.0](https://github.com/prashantkalkar/stateful_application_module/compare/v0.2.0...v0.3.0)

## v0.2.0

Changes:
* Updated to support image override at node level. by @prashantkalkar in [#7](https://github.com/prashantkalkar/stateful_application_module/pull/7)

Full Changelog: [v0.1.0...v0.2.0](https://github.com/prashantkalkar/stateful_application_module/compare/v0.1.0...v0.2.0)

## v0.1.0

First release to manage stateful application on AWS.

Full Changelog: https://github.com/prashantkalkar/stateful_application_module/commits/v0.1.0
