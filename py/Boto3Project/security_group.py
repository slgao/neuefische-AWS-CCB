import requests


class SecurityGroup(object):
    """Documentation for SecurityGroup"""

    def __init__(self, config):
        super(SecurityGroup, self).__init__()
        self.config = config

    def set_client(self, client):
        """Set the AWS client for security group operations."""
        self.client = client

    def get_my_ip(self):
        return requests.get("https://checkip.amazonaws.com").text.strip()

    def set_ip(self):
        """Set the IP address to use for security group rules."""
        ip = self.get_my_ip() if self.config.use_myip else "0.0.0.0/0"
        self.ip = ip

    def create_security_group(self, group_name, vpc_id, description="Default SG"):
        """Create a security group in the specified VPC."""
        response = self.client.create_security_group(
            GroupName=group_name, Description=description, VpcId=vpc_id
        )
        self.security_group_id = response["GroupId"]
        print(
            f"Security Group {group_name}:{self.security_group_id} created in VPC {vpc_id}"
        )

    def authorize_securtiy_group(self, port=22, protocol="tcp", description="SSH access"):
        self.set_ip()
        self.client.authorize_security_group_ingress(
            GroupId=self.security_group_id,
            IpPermissions=[
                {
                    "IpProtocol": protocol,  # Protocol type
                    "FromPort": port,  # Starting port - SSH
                    "ToPort": port,  # Ending port
                    "IpRanges": [{"CidrIp": f"{self.ip}/32", "Description": description}],
                }
            ],
        )

    def create_tags(self):
        """Create tags for the security group."""
        security_group_id = self.security_group_id
        group_name = self.config.security_group_name

        if not security_group_id:
            raise ValueError(
                "Security Group ID is not set. Please create a security group first."
            )
        if not group_name:
            raise ValueError(
                "Security Group Name is not set. Please provide a name for the security group."
            )
        # Create tags for the security group
        self.client.create_tags(
            Resources=[security_group_id], Tags=[{"Key": "Name", "Value": group_name}]
        )
