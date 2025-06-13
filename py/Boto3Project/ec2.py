import boto3

class EC2(object):
    """Documentation for EC2

    """
    def __init__(self):
        super(EC2, self).__init__()
        
    def get_client(self):
        """Get the AWS client for EC2 operations."""
        self.client = boto3.client('ec2')
        return self.client
