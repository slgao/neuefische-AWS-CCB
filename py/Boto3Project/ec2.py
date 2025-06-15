import boto3
import botocore


class EC2(object):
    """Documentation for EC2"""

    def __init__(self, config=None):
        super(EC2, self).__init__()
        self.config = config

    def get_client(self):
        """Get the AWS client for EC2 operations."""
        self.client = boto3.client("ec2")
        return self.client

    def get_image_id(self):
        """Get the latest Amazon Linux 2 AMI ID."""
        response = self.client.describe_images(
            Filters=[
                {"Name": "name", "Values": ["amzn2-ami-hvm-*-x86_64-gp2"]},
                {"Name": "state", "Values": ["available"]},
                {"Name": "architecture", "Values": ["x86_64"]},
            ],
            Owners=["amazon"],
        )
        images = sorted(
            response["Images"], key=lambda x: x["CreationDate"], reverse=True
        )
        return images[0]["ImageId"] if images else None

    def create_and_download_key_pair(self):
        """Download the key pair for EC2 instances."""
        try:
            self.client.describe_key_pairs(KeyNames=[self.config.key_pair_name])
            print(
                f"Key pair '{self.config.key_pair_name}' already exists. Skipping creation."
            )
            return
        except botocore.exceptions.ClientError as e:
            if "InvalidKeyPair.NotFound" in str(e):
                print(f"Key pair '{self.config.key_pair_name}' not found. Creating...")
            else:
                raise

        response = self.client.create_key_pair(KeyName=self.config.key_pair_name)
        with open(f"{self.config.key_pair_name}.pem", "w") as file:
            file.write(response["KeyMaterial"])
        print(f"Key pair {self.config.key_pair_name} downloaded successfully.")

    def run_instances(self, security_group_ids=None, subnet_id=None):
        """Run an EC2 instance with the latest Amazon Linux 2 AMI."""
        image_id = self.get_image_id()
        if not image_id:
            raise Exception("No suitable AMI found.")

        # run instance with public ip address in the specified subnet
        response = self.client.run_instances(
            ImageId=image_id,
            InstanceType=self.config.instance_type,
            MinCount=1,
            MaxCount=1,
            KeyName=self.config.key_pair_name,
            TagSpecifications=[
                {
                    "ResourceType": "instance",
                    "Tags": [{"Key": "Name", "Value": self.config.ec2_instance_name}],
                }
            ],
            NetworkInterfaces=[
                {
                    "DeviceIndex": 0,
                    "AssociatePublicIpAddress": True,
                    "SubnetId": subnet_id,
                    "Groups": security_group_ids
                }
            ],
        )
        instance_id = response["Instances"][0]["InstanceId"]
        print(f"EC2 instance {instance_id} run successfully.")
        return instance_id
