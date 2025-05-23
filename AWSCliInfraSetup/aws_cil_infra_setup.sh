#!/bin/bash

# VPC:
#   Must support at least 50 Private IPs and 10 Public IPs.,
#   Choose a suitable CIDR block and create subnets accordingly (public & private).,

vpc_name="MyVPC"
pub_sub1_name="Public Subnet"
priv_sub1_name="Private Subnet"
ip="10.0.0.0"
net_mask_vpc="26"
cidr_block="$ip/$net_mask_vpc"	# have 64 total private IPs
region=us-west-2
az=us-west-2a
igw_name="MY-IGW"
rtb_name="Public Route Table"
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
    # --------------------------------------------------------------------------
    # Detach and delete Internet Gateways
    igw_ids=$(aws ec2 describe-internet-gateways \
		  --region "$region" \
		  --filters "Name=attachment.vpc-id,Values=$vpc_id" \
		  --filters "Name=tag:Name,Values=$igw_name" \
		  --query "InternetGateways[*].InternetGatewayId" \
		  --output text)
    for igw_id in $igw_ids; do
	echo "Detaching and deleting IGW: $igw_id"
	aws ec2 detach-internet-gateway --region "$region" --internet-gateway-id "$igw_id" --vpc-id "$vpc_id"
	aws ec2 delete-internet-gateway --region "$region" --internet-gateway-id "$igw_id" && echo "IGW deleted!"
    done
    # --------------------------------------------------------------------------
    # Delete subnets if any exist. (Consider using for loop, now hard coded)
    pub_sub1_id=$(aws ec2 describe-subnets \
		     --region "$region" \
		     --filters "Name=vpc-id,Values=$vpc_id" \
		     --filters "Name=tag:Name,Values=$pub_sub1_name" \
		     --query "Subnets[*].SubnetId" \
		     --output text)
    echo "public subnet1 ID: $pub_sub1_id"
    if [[ -n "$pub_sub1_id" ]]; then # if the public subnet1 exists
	echo "Deleting Public Subnet: $pub_sub1_id"
	aws ec2 delete-subnet --region "$region" --subnet-id "$pub_sub1_id" && echo "public subnet1 deleted!"
    fi
    priv_sub1_id=$(aws ec2 describe-subnets \
		     --region "$region" \
		     --filters "Name=vpc-id,Values=$vpc_id" \
		     --filters "Name=tag:Name,Values=$priv_sub1_name" \
		     --query "Subnets[*].SubnetId" \
		     --output text)
    echo "private subnet1 ID: $priv_sub1_id"
    if [[ -n "$priv_sub1_id" ]]; then # if the public subnet1 exists
	echo "Deleting Private Subnet: $priv_sub1_id"
	aws ec2 delete-subnet --region "$region" --subnet-id "$priv_sub1_id" && echo "private subnet1 deleted!"
    fi
    # --------------------------------------------------------------------------
    # Delete custom route tables -- Pay attention to the rtb has dependencies and cannot be deleted.(the order to delete it)
    rtb_ids=$(aws ec2 describe-route-tables \
		  --region "$region" \
		  --filters "Name=vpc-id,Values=$vpc_id" \
		  --filters "Name=tag:Name,Values=$rtb_name" \
		  --query "RouteTables[*].RouteTableId" \
		  --output text)

    for rtb_id in $rtb_ids; do
	echo "Deleting Route Table: $rtb_id"
	aws ec2 delete-route-table --region "$region" --route-table-id "$rtb_id" && \
	    echo "RouteTable ID: $rtb_id deleted!"
    done
    # --------------------------------------------------------------------------
    # delete the VPC at the end.
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
pub_sub1_id=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block $cidr_block_pubsub1 \
  --availability-zone $az \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$pub_sub1_name\"}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Public Subnet created: $pub_sub1_id"

# Enable Public IP on launch
aws ec2 modify-subnet-attribute \
    --subnet-id $pub_sub1_id \
    --map-public-ip-on-launch

# Create private Subnet
net_mask_privsub1="27"
start_ip_privsub="10.0.0.32"
cidr_block_privsub1="$start_ip_privsub/$net_mask_privsub1"
priv_sub1_id=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block $cidr_block_privsub1 \
  --availability-zone $az \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$priv_sub1_name\"}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Private Subnet created: $priv_sub1_id"

##########################################################################################
# Creating an IGW
igwid=$(aws ec2 create-internet-gateway \
	--tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=\"$igw_name\"}]" \
--query 'InternetGateway.InternetGatewayId' \
--output text)
echo "Internet Gateway created: $igwid"

# attaching the IGW to the VPC
aws ec2 attach-internet-gateway --internet-gateway-id $igwid --vpc-id $vpc_id
echo "IGW attached: $igwid"

##########################################################################################
# Create Route Table
rtbpubid1=$(aws ec2 create-route-table \
    --vpc-id $vpc_id \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=\"$rtb_name\"}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Create a Route
aws ec2 create-route \
    --route-table-id $rtbpubid1 \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $igwid

# Subnet Associations
aws ec2 associate-route-table --subnet-id $pub_sub1_id --route-table-id $rtbpubid1
echo "Public route table created and associated."
