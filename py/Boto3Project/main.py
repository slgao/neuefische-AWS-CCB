# Final goal:
# ---
# A VPC with public and private subnets
# Route tables and routes for internet access An internet gateway for the VPC
# Security groups to control access to resources EC2 instances for running applications
# RDS instances for database storage

from config import Config
from vpc import VPC


def main():
    config = Config()
    
    # create a VPC
    vpc = VPC()
    vpc.get_client()
    vpc_id = vpc.create_vpc(cidr_block=config.vpc_cidr)
    vpc.create_tags(vpc_name=config.vpc_name)
    vpc.enable_DNS()


if __name__ == "__main__":
    main()
