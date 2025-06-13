import boto3


class Subnet(object):
    """Documentation for Subnet"""

    def __init__(self, config):
        super(Subnet, self).__init__()
        self.config = config

    def set_client(self, client):
        """Set the AWS client for subnet operations."""
        self.client = client

    def create_subnet(
        self, name, cidr_block, az, vpc_id, map_public_ip_on_launch=False
    ):
        """Create a subnet in the specified VPC."""
        subnet = self.client.create_subnet(
            CidrBlock=cidr_block,
            AvailabilityZone=az,
            VpcId=vpc_id,
        )
        subnet_id = subnet["Subnet"]["SubnetId"]
        print(f"{name}:{subnet_id} created with CIDR block {cidr_block} in AZ {az}")
        self.client.create_tags(
            Resources=[subnet_id], Tags=[{"Key": "Name", "Value": name}]
        )
        if map_public_ip_on_launch:
            self.client.modify_subnet_attribute(
                SubnetId=subnet_id, MapPublicIpOnLaunch={"Value": True}
            )
        return subnet_id
