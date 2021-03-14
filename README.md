# workshop-cookbook

To run: 
terraform init
terraform apply -parallelism=${DESIRED_PARALLELISM} --var 'cluster_count=${NUM_CLUSTERS}'

Set the -parallelism to some large number. The default is 8. I'm guessing that the scripts will run more quickly the larger you set it. I've been using -parallelism=1200 (more than the number of resources being created). 

Requirements:
- Public and private key in the root directory of the project. The public key should have permissions 644 and be called id_rsa.pub, and the private key should have permissions 600 and be called id_rsa. 
- Appropriate AWS EC2 vCPU, VPC, and EIP limits for us-east-2 or whichever aws region you'd like provision the clusters in. 

Notes: 
- It might take around 7 minutes for the bootstrap process (module.workshop[43].null_resource.wait_for_bootstrap_to_finish) on the nodes to finish....
- These scripts will isolate each cluster inside it's own VPC. 
