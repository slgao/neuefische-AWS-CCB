# This file contains configuration settings for the AWS resources
import yaml


class Config:
    def __init__(self, config_file="config.yml"):
        super(Config, self).__init__()
        with open(config_file, "r") as f:
            cfg = yaml.safe_load(f)

        self.key_pair_name = cfg["ec2"]["key_pair_name"]
        self.ec2_instance_name = cfg["ec2"]["ec2_instance_name"]
        self.instance_type = cfg["ec2"]["instance_type"]
        self.az = cfg["ec2"]["az"]
        self.az2 = cfg["ec2"]["az2"]
        self.region = cfg["ec2"]["region"]

        self.vpc_ip = cfg["vpc"]["ip"]
        self.vpc_net_mask = cfg["vpc"]["net_mask"]
        self.vpc_cidr = f"{self.vpc_ip}.0/{self.vpc_net_mask}"
        self.vpc_name = cfg["vpc"]["name"]

        self.subnet_net_mask = cfg["subnets"]["net_mask"]
        self.public_subnet1_name = cfg["subnets"]["public_subnet1"]["name"]
        self.private_subnet1_name = cfg["subnets"]["private_subnet1"]["name"]
        self.public_subnet2_name = cfg["subnets"]["public_subnet2"]["name"]
        self.private_subnet2_name = cfg["subnets"]["private_subnet2"]["name"]
        self.public_subnet1_cidr = cfg["subnets"]["public_subnet1"]["cidr"]
        self.private_subnet1_cidr = cfg["subnets"]["private_subnet1"]["cidr"]
        self.public_subnet2_cidr = cfg["subnets"]["public_subnet2"]["cidr"]
        self.private_subnet2_cidr = cfg["subnets"]["private_subnet2"]["cidr"]

        self.igw_name = cfg["network"]["igw_name"]
        self.public_route_table_name = cfg["network"]["public_route_table_name"]

        self.use_myip = cfg["security"]["use_myip"]
        self.security_group_name = cfg["security"]["group_name"]
        self.ssh_port = cfg["security"]["ssh_port"]

        self.db_subnet_group = cfg["rds"]["db_subnet_group_name"]
        self.db_instance_identifier = cfg["rds"]["instance_identifier"]
        self.db_name = cfg["rds"]["name"]
        self.db_instance_class = cfg["rds"]["instance_class"]
        self.db_engine = cfg["rds"]["engine"]
        self.db_engine_version = cfg["rds"]["engine_version"]
        self.db_master_username = cfg["rds"]["master_username"]
        self.db_master_password = cfg["rds"]["master_password"]
        self.allocated_storage = cfg["rds"]["allocated_storage"]
        self.db_subnet_group_name = cfg["rds"]["db_subnet_group_name"]
        self.rds_port = cfg["rds"]["port"]
