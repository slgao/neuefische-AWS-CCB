# This file contains configuration settings for the AWS resources

class Config(object):
    """Configuration settings for AWS resources.
       The configs can be read from a file.

    """
    def __init__(self):
        super(Config, self).__init__()
        self.az = 'us-west-2a'
        self.region = 'us-west-2'
        self.vpc_ip = "10.0.0"
        self.vpc_net_mask = "26"
        self.vpc_cidr = f"{self.vpc_ip}.0/{self.vpc_net_mask}"
        self.vpc_name = "MyVPC"
        self.public_subnet_name = "PublicSubnet"
        self.subnet_net_mask = "28"
        self.public_subnet_cidr = f"{self.vpc_ip}.0/{self.subnet_net_mask}"
        self.private_subnet_name = "PrivateSubnet"
        self.private_subnet_cidr = f"{self.vpc_ip}.16/{self.subnet_net_mask}"

        self.igw_name = "MyIGW"
        self.public_route_table_name = "PublicRouteTable"

        self.use_myip = True
        self.security_group_name = "MySecurityGroup"
        self.ssh_port = 22
