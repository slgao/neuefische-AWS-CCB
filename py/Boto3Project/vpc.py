# This file contains methods to interact with the VPC

import boto3

class VPC(object):
    """Documentation for VPC

    """
    def __init__(self):
        super(VPC, self).__init__()

    def get_client(self):
        """Get the AWS client for VPC operations."""
        self.client = boto3.client('ec2')
        

    def create_vpc(self, cidr_block):
        vpc = self.client.create_vpc(
            CidrBlock=cidr_block,
        )
        self.vpc_id = vpc['Vpc']['VpcId']
        print(f"{self.vpc_id} created with CIDR block {cidr_block}")
        return self.vpc_id

    def create_tags(self, vpc_name):
        self.client.create_tags(Resources=[self.vpc_id], Tags=[{'Key': 'Name', 'Value': vpc_name}])
        
    def enable_DNS(self):
        self.client.modify_vpc_attribute(VpcId=self.vpc_id, EnableDnsHostnames={'Value': True})


