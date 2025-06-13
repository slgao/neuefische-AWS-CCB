class InternetGateway(object):
    """Documentation for InternetGateway

    """
    def __init__(self, config=None):
        super(InternetGateway, self).__init__()
        self.config = config

    def set_client(self, client):
        """Set the AWS client for Internet Gateway operations."""
        self.client = client

    def create_internet_gateway(self):
        """Create an Internet Gateway."""
        igw = self.client.create_internet_gateway()
        self.igw_id = igw['InternetGateway']['InternetGatewayId']
        print(f"Internet Gateway {self.igw_id} created")
        return self.igw_id

    def create_tags(self):
        """Create tags for the Internet Gateway."""
        self.client.create_tags(Resources=[self.igw_id], Tags=[{'Key': 'Name', 'Value': self.config.igw_name}])
        print(f"Tags created for Internet Gateway {self.igw_id} with Name: {self.config.igw_name}")
    
    def attach_internet_gateway(self, vpc_id):
        """Attach the Internet Gateway to the specified VPC."""
        response = self.client.attach_internet_gateway(
            InternetGatewayId=self.igw_id,
            VpcId=vpc_id
        )
        print(f"Internet Gateway {self.igw_id} attached to VPC {vpc_id}")
    
        
