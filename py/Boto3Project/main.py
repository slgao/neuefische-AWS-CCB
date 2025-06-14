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
from security_group import SecurityGroup
from rds import RDS


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
    public_subnet_names = [config.public_subnet1_name, config.public_subnet2_name]
    private_subnet_names = [config.private_subnet1_name, config.private_subnet2_name]
    azs = [config.az, config.az2]
    # create public subnets
    for subnet_name, az in zip(public_subnet_names, azs):
        # create public subnets and get their ids at the same time
        subnet.create_subnet(
            name=subnet_name,
            cidr_block=(
                config.public_subnet1_cidr
                if "1" in subnet_name
                else config.public_subnet2_cidr
            ),
            az=az,
            vpc_id=vpc_id,
            map_public_ip_on_launch=True,
        )
    # create private subnets
    for subnet_name, az in zip(private_subnet_names, azs):
        subnet.create_subnet(
            name=subnet_name,
            cidr_block=(
                config.private_subnet1_cidr
                if "1" in subnet_name
                else config.private_subnet2_cidr
            ),
            az=az,
            vpc_id=vpc_id,
            map_public_ip_on_launch=False,
        )
    # Print the subnet IDs
    print(f"Subnets Created ----: {config.subnet_ids}")

    # Internet Gateway Operations
    igw = InternetGateway(config)
    igw.set_client(ec2)
    igw.create_internet_gateway()
    igw.create_tags()
    igw.attach_internet_gateway(vpc_id)

    # Route Table Operations
    rt = RouteTable(config)
    rt.set_client(ec2)
    # create route table for public subnet
    public_route_table_id = rt.create_route_table(vpc_id)
    # create tags for public route table
    rt.create_tags(route_table_id=public_route_table_id)
    # create route for public subnet to internet gateway
    rt.create_route(route_table_id=public_route_table_id, gateway_id=igw.igw_id)
    # associate route table with public subnet
    rt.associate_route_table(
        route_table_id=public_route_table_id,
        subnet_id=config.subnet_ids[config.public_subnet1_name],
    )

    # Security Group Operations
    # Create security groups
    sg = SecurityGroup(config)
    sg.set_client(ec2)
    sg.create_security_group(config.security_group_name, vpc_id)
    sg.authorize_securtiy_group(port=config.ssh_port, description="Allow SSH access")
    sg.create_tags()

    # RDS Operations
    rds = RDS(config)
    # Only get subnet ids from public subnets
    public_subnet_ids = [
        config.subnet_ids[config.public_subnet1_name],
        config.subnet_ids[config.public_subnet2_name],
    ]
    rds.create_db_subnet_group(subnet_ids=public_subnet_ids)
    # Create security group for RDS
    sg.create_security_group(config.security_group_name + "-rds", vpc_id)
    # Authorize security group for RDS
    sg.authorize_securtiy_group(port=config.rds_port, description="Allow RDS access")
    rds.create_RDS_instance(rds_sg_ids=[sg.security_group_id])


if __name__ == "__main__":
    main()
