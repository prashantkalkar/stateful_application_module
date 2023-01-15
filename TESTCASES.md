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

# Multi node cluster - Failure
- Start cluster with multiple nodes - all 3 tries to come up?

# Change or instance type 3 node cluster - Success

# Change or instance type 3 node cluster - Failure
- Does the process stop?
- Will the cluster survive?

# Different nodes look different

# Adding node/nodes to existing cluster