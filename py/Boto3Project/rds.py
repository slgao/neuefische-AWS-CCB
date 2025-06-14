import boto3

class RDS(object):
    """Documentation for RDS

    """
    def __init__(self, config=None):
        super(RDS, self).__init__()
        self.config = config
        self.get_client()
        
    def get_client(self):
        """Get the AWS client for RDS operations."""
        self.rds_client = boto3.client('rds')
        return self.rds_client

    def create_db_subnet_group(self, subnet_ids):
        # Check if DB Subnet Group exists
        try:
            self.rds_client.describe_db_subnet_groups(DBSubnetGroupName=self.config.db_subnet_group)
            print(f"DB subnet group '{self.config.db_subnet_group}' exists.")
        except self.rds_client.exceptions.DBSubnetGroupNotFoundFault:
            print("Creating DB Subnet Group...")
            self.rds_client.create_db_subnet_group(
                DBSubnetGroupName=self.config.db_subnet_group,
                DBSubnetGroupDescription='DB subnet group for private RDS',
                SubnetIds=subnet_ids,
                Tags=[{'Key': 'Name', 'Value': self.config.db_subnet_group}]
            )
            print(f"DB Subnet Group '{self.config.db_subnet_group}' created successfully.")

    def create_RDS_instance(self, rds_sg_ids, enhanced_monitoring=False):
        """Create an RDS instance."""
        try:
            self.rds_client.describe_db_instances(DBInstanceIdentifier=self.config.db_instance_identifier)
            print(f"RDS instance '{self.config.db_instance_identifier}' already exists.")
        except self.rds_client.exceptions.DBInstanceNotFoundFault:
            print("Creating RDS instance...")
            # Create RDS Instance
            self.rds_client.create_db_instance(
                DBInstanceIdentifier=self.config.db_instance_identifier,
                DBInstanceClass=self.config.db_instance_class,
                Engine=self.config.db_engine,
                EngineVersion=self.config.db_engine_version,
                MasterUsername=self.config.db_master_username,
                MasterUserPassword=self.config.db_master_password,
                AllocatedStorage=self.config.allocated_storage,
                DBName=self.config.db_name,
                DBSubnetGroupName=self.config.db_subnet_group_name,
                VpcSecurityGroupIds=rds_sg_ids,
                PubliclyAccessible=False
            )
            print(f"RDS instance '{self.config.db_instance_identifier}' created successfully.")

            print("Waiting for RDS to become available...")
            self.rds_client.get_waiter('db_instance_available').wait(DBInstanceIdentifier=self.config.db_instance_identifier)

            # Disable enhanced monitoring
            if not enhanced_monitoring:
                self.rds_client.modify_db_instance(
                    DBInstanceIdentifier=self.config.db_instance_identifier,
                    MonitoringInterval=0,
                    ApplyImmediately=True
                )

            endpoint = self.rds_client.describe_db_instances(
                DBInstanceIdentifier=self.config.db_instance_identifier
            )['DBInstances'][0]['Endpoint']['Address']
            print(f"RDS Endpoint: {endpoint}")


