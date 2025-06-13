# This file contains configuration settings for the AWS resources

class Config(object):
    """Configuration settings for AWS resources.
       The configs can be read from a file.

    """
    def __init__(self):
        super(Config, self).__init__()
        self.vpc_ip = "10.0.0.0"
        self.vpc_net_mask = "26"
        self.vpc_cidr = f"{self.vpc_ip}/{self.vpc_net_mask}"
        self.vpc_name = "MyVPC"
