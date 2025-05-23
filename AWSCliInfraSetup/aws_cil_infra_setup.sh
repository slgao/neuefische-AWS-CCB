#!/bin/bash

# VPC:
#   Must support at least 50 Private IPs and 10 Public IPs.,
#   Choose a suitable CIDR block and create subnets accordingly (public & private).,

vpc_name="MyVPC"
cidr_block="10.0.0.0/26"	# have 64 total private IPs
# Region can be specified in the aws config file, which will be us-west-2 by default

# Creating a VPC, if there exists a VPC with the same Name tag == MyVPC, delete it first.
# First get the vpc id from the cloud.
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$vpc_name" \
  --query "Vpcs[*].VpcId" \
  --output text)
if [[ -n "$vpc_id" ]]; then
    echo "There is already existing VPC named $vpc_name"
    # TODO:detach and delete everything that the vpc is using
    aws ec2 delete-vpc --vpc-id "$vpc_id"
    echo "The old VPC named $vpc_name has been deleted!"
else
    echo "No existing VPC named $vpc_name"
fi    
# Create a new VPC
vpc_id=$(aws ec2 create-vpc \
    --cidr-block $cidr_block \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=\"$vpc_name\"}]" \
    --query 'Vpc.VpcId' \
    --output text)
echo "VPC created: $vpc_id"

# Enable DNS Hostnames

aws ec2 modify-vpc-attribute \
   --vpc-id $vpc_id \
   --enable-dns-hostnames "{\"Value\":true}"
