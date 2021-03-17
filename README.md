# workshop-cookbook

Requirements:
- public and private key in root directory of repository. public key called id_rsa.pub, private key called id_rsa. 
- appropriate AWS EC2 vCPU, VPC, and EIP limits for us-east-1 or whichever aws region you'd like the scripts to provision into 

Notes: 
- If you get an 

Error: timeout - last error: dial tcp 52.15.153.23:22: i/o timeout

, just run 'terraform apply' again (without calling terraform destroy). I'm guessing this error is caused by the AWS cli itself that terraform is calling....

- might take around 7 minutes (might even take up to 10 minutes) for the package locks to be released on the master and worker nodes prior to the machine-bootstrap scripts starting....
- might see 'aws_instace.master is creating......' output for about 5 minutes before the machine-bootstrap script starts running on the masters
- will isolate each cluster inside it's own VPC
