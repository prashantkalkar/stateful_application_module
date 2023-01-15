
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