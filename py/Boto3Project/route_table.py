class RouteTable(object):
    """Documentation for RouteTable"""

    def __init__(self, config=None):
        super(RouteTable, self).__init__()
        self.config = config

    def set_client(self, client):
        """Set the AWS client for Route Table operations."""
        self.client = client

    def create_route_table(self, vpc_id):
        """Create a route table in the specified VPC."""
        route_table = self.client.create_route_table(VpcId=vpc_id)
        route_table_id = route_table["RouteTable"]["RouteTableId"]
        print(f"Route Table {route_table_id} created in VPC {vpc_id}")
        return route_table_id

    def create_tags(self, route_table_id):
        """Create tags for the route table."""
        name = self.config.public_route_table_name
        self.client.create_tags(
            Resources=[route_table_id], Tags=[{"Key": "Name", "Value": name}]
        )
        print(f"Tags created for Route Table {route_table_id} with Name: {name}")

    def create_route(
        self, route_table_id, gateway_id, destination_cidr_block="0.0.0.0/0"
    ):
        """Create a route in the route table."""
        self.client.create_route(
            RouteTableId=route_table_id,
            GatewayId=gateway_id,
            DestinationCidrBlock=destination_cidr_block,
        )
        print(
            f"Route created in Route Table {route_table_id} to Gateway {gateway_id} for CIDR block {destination_cidr_block}"
        )

    def associate_route_table(self, route_table_id, subnet_id):
        """Associate the route table with a subnet."""
        self.client.associate_route_table(
            RouteTableId=route_table_id, SubnetId=subnet_id
        )
        print(f"Route Table {route_table_id} associated with Subnet {subnet_id}")
