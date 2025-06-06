#!/bin/bash

echo "This script helps you to create an EC2 instance:"
read -p "Please specify the instance type[t2.micro]:" instance_type 
echo "Instance type is: ${instance_type:-t2.micro}"
echo "Please provide the key pair name[vockey]:"
read key_pair_name
echo "key pair name is: ${key_pair_name:-vockey}"
echo "Please provide the security groups:"
read security_groups
echo "Please provide the AMI ID:"
read ami_id
echo "Please specify a region[us-west-2]:"
read region
echo "Region is: ${region:-us-west-2}"

aws ec2 run-instances \ 
--image-id "$ami_id" \ 
--instance-type "$instance_type" \
--key-name "$key_pair_name" \
--security-groups "$security_groups" \
--region "$region"
if [ $? -eq 0 ]; then
    echo "Instance created successfully."
else
    echo "Instance was not created successfully."
fi    
