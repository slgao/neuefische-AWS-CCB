#!/bin/bash

# VPC:
#   Must support at least 50 Private IPs and 10 Public IPs.,
#   Choose a suitable CIDR block and create subnets accordingly (public & private).,

vpc_name="MyVPC"
pub_sub1_name="Public Subnet"
ip="10.0.0.0"
net_mask_vpc="26"
cidr_block="$ip/$net_mask_vpc"	# have 64 total private IPs
region=us-west-2
az=us-west-2a
echo "VPC CIDR BLOCK is set to: $cidr_block"
# Region can be specified in the aws config file, which will be us-west-2 by default

# Creating a VPC, if there exists a VPC with the same Name tag == MyVPC, delete it first.
# First get the vpc id from the cloud.
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$vpc_name" \
  --query "Vpcs[*].VpcId" \
  --output text)
echo "VPC ID from query: $vpc_id"
if [[ -n "$vpc_id" ]]; then
    echo "There is already existing VPC named $vpc_name"
    # TODO:detach and delete everything that the vpc is using, then delete the VPC
    # Delete subnets if any exist.
    pub_sub1_id=$(aws ec2 describe-subnets \
		     --region "$region" \
		     --filters "Name=vpc-id,Values=$vpc_id" \
		     --filters "Name=tag:Name,Values=$pub_sub1_name" \
		     --query "Subnets[*].SubnetId" \
		     --output text)
    echo "public subnet1 ID: $pub_sub1_id"
    if [[ -n "$pub_sub1_id" ]]; then # if the public subnet1 exists
	echo "Deleting Subnet: $pub_sub1_id"
	aws ec2 delete-subnet --region "$region" --subnet-id "$pub_sub1_id" && echo "public subnet1 deleted!"
    fi
    aws ec2 delete-vpc --vpc-id "$vpc_id" && echo "The old VPC named $vpc_name has been deleted!"
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

# Create Subnets
# TODO: We can assign the number of Public Subnets
net_mask_pubsub1="27"
cidr_block_pubsub1="$ip/$net_mask_pubsub1"
pub_sub1=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block $cidr_block_pubsub1 \
  --availability-zone $az \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$pub_sub1_name\"}]" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Public Subnet created: $pub_sub1"

# Enable Public IP on launch
aws ec2 modify-subnet-attribute \
  --subnet-id $pub_sub1 \
  --map-public-ip-on-launch
