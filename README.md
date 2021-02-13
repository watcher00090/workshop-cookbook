# workshop-cookbook

Requirements:
- public and private key in root directory of repository. public key called id_rsa.pub, private key called id_rsa. 
- appropriate AWS EC2 vCPU, VPC, and EIP limits for us-east-1 or whichever aws region you'd like the scripts to provision into

Notes: 
- might take around 4 minutes for the package locks to be released on the master nodes prior to the machine-bootstrap scripts starting....
- will isolate each cluster inside it's own VPC
