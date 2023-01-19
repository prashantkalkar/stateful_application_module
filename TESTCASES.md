# Single Node cluster
- Does the cluster come up?
Observation: For Amazon linux, the secondary ENI is installed as eth1. 
TODO - We still need to test whether Kafka or Cassandra like services will work properly. 
Also, this waste one IP per node. 

# Single Node cluster - Failure
- What happens?
Observation: Terraform fails due to capacity requirement.  

# Multi node cluster
- Start cluster with multiple nodes - all 3 tries to come up?
Expectation: Additional 2 nodes should come up. Rolling update script should skip all ASGs. 

# 2 node cluster with 3rd ASG was not created
- Change of instance type.
Expected behaviour: All 3 ASGs should be updated with latest LT. 3rd ASG should launch the instance. 
First 2 ASG will not change the instance. The rolling update script should roll first 2 ASGs only after all 3 are up.

# Multi node cluster - Failure
- Start cluster with multiple nodes - all 3 tries to come up?

# Change or instance type 3 node cluster - Success

# Change or instance type 3 node cluster - Failure
- Does the process stop?
- Will the cluster survive?

# Different nodes look different

# Adding node/nodes to existing cluster

# Should not perform rolling update when any one instance is not healthy 

# Should not perform rolling update when no change is required.
