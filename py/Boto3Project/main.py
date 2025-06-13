# Final goal:
# ---
# A VPC with public and private subnets
# Route tables and routes for internet access An internet gateway for the VPC
# Security groups to control access to resources EC2 instances for running applications
# RDS instances for database storage

from config import Config
from ec2 import EC2
from vpc import VPC
from subnet import Subnet
from internet_gateway import InternetGateway
from route_table import RouteTable

def main():
    config = Config()

    ec2 = EC2()
    ec2 = ec2.get_client()
    
    # VPC Operations
    # create a VPC
    vpc = VPC()
    vpc.set_client(ec2)
    vpc_id = vpc.create_vpc(cidr_block=config.vpc_cidr)
    vpc.create_tags(vpc_name=config.vpc_name)
    vpc.enable_DNS()


    # Subnet Operations
    subnet = Subnet(config)
    subnet.set_client(ec2)
    # create public subnet
    subnet.create_subnet(
        name=config.public_subnet_name,
        cidr_block=config.public_subnet_cidr,
        az=config.az,
        vpc_id=vpc_id,
        map_public_ip_on_launch=True,
    )
    # create private subnet
    subnet.create_subnet(
        name=config.private_subnet_name,
        cidr_block=config.private_subnet_cidr,
        az=config.az,
        vpc_id=vpc_id,
        map_public_ip_on_launch=False,
    )

    # Internet Gateway Operations
    igw = InternetGateway(config)
    igw.set_client(ec2)
    igw.create_internet_gateway()
    igw.create_tags()
    igw.attach_internet_gateway(vpc_id)
    
    # Route Table Operations
    


if __name__ == "__main__":
    main()
