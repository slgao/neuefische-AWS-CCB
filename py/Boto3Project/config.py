# This file contains configuration settings for the AWS resources

class Config(object):
    """Configuration settings for AWS resources.
       The configs can be read from a file.

    """
    def __init__(self):
        super(Config, self).__init__()
        self.az = 'us-west-2a'
        self.az2 = 'us-west-2b'
        self.region = 'us-west-2'
        self.vpc_ip = "10.0.0"
        self.vpc_net_mask = "26"
        self.vpc_cidr = f"{self.vpc_ip}.0/{self.vpc_net_mask}"
        self.vpc_name = "MyVPC"
        
        self.subnet_net_mask = "28"
        self.public_subnet1_name = "PublicSubnet1"
        self.public_subnet2_name = "PublicSubnet2"
        self.private_subnet1_name = "PrivateSubnet1"
        self.private_subnet2_name = "PrivateSubnet2"
        self.public_subnet1_cidr = f"{self.vpc_ip}.0/{self.subnet_net_mask}"
        self.private_subnet1_cidr = f"{self.vpc_ip}.16/{self.subnet_net_mask}"
        self.public_subnet2_cidr = f"{self.vpc_ip}.32/{self.subnet_net_mask}"
        self.private_subnet2_cidr = f"{self.vpc_ip}.48/{self.subnet_net_mask}"

        self.igw_name = "MyIGW"
        self.public_route_table_name = "PublicRouteTable"

        self.use_myip = True
        self.security_group_name = "MySecurityGroup"
        self.ssh_port = 22

        self.db_subnet_group = "MyDBSubnetGroup"
        self.db_instance_identifier = "MyRDSInstance"
        self.db_name = "MyDatabase"
        self.db_instance_class = "db.t3.micro"
        self.db_engine = "mysql"
        self.db_master_username = "admin"
        self.db_master_password = "password123"
        self.allocated_storage = 20
        self.db_subnet_group_name = "MyDBSubnetGroup"
        self.rds_port = 3306
        self.db_engine_version = "8.0.33"
        
