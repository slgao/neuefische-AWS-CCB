#!/bin/bash
set -e  # Stop script on error

vpc_name="wp_vpc"
pub_sub1_name="Public Subnet 1"
priv_sub1_name="Private Subnet 1"
pub_sub2_name="Public Subnet 2"
priv_sub2_name="Private Subnet 2"
use_myip=true
ip="10.0.0.0"
net_mask_vpc="26"
cidr_block="$ip/$net_mask_vpc"	# have 64 total private IPs
region=us-west-2		# region can be set in the aws config
az=us-west-2a
az2=us-west-2b
igw_name="MY-IGW"
rtb_name="Public Route Table"
key_name="wp-key"

# RDS instance
db_subnet_group="DB-Subnet-Group"
RDS_sg_name="RDS-Security-Group"
RDS_identifier="RDS-Instance"
db_instance_class="db.t3.micro"
db_engine="mysql"
db_engine_version="8.0"
master_username="admin"
master_password="wp-password123!"
db_name="mydatabase"
allocated_storage=100
key_name="wp-key"
key_file="labsuser.pem"


# Create a new key pair, check if the key pair already exists
if aws ec2 describe-key-pairs --key-names "$key_name" --no-cli-pager >/dev/null 2>&1; then
    echo "Key pair '$key_name' already exists. Skipping creation."
else
    echo "Key pair '$key_name' does not exist. Creating new key pair..."
    aws ec2 create-key-pair --key-name "$key_name" --query 'KeyMaterial' --output text --no-cli-pager > "$key_file"
    if [ $? -eq 0 ]; then
        echo "Key pair '$key_name' created successfully. Private key saved to $key_file"
        # Set appropriate permissions for the key file
        chmod 400 "$key_file"
    else
        echo "Failed to create key pair '$key_name'."
        exit 1
    fi
fi

# # Create the key pair
# echo "Creating key pair named $key_name..."
# aws ec2 create-key-pair \
#   --key-name $key_name \
#   --region $region \
#   --query 'KeyMaterial' \
#   --output text > $key_file
# echo "Key pair created and private key saved to $key_file"

echo "VPC CIDR BLOCK is set to: $cidr_block"
# Region can be specified in the aws config file, which will be us-west-2 by default

# Creating a VPC, if there exists a VPC with the same Name tag == MyVPC, delete it first.
# First get the vpc id from the cloud.
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$vpc_name" \
  --query "Vpcs[*].VpcId" \
  --output text)
echo "VPC ID from query: $vpc_id"
if [[ -n "$vpc_id" ]]; then
    echo "There is already existing VPC named $vpc_name"
    # TODO:detach and delete everything that the vpc is using, then delete the VPC
    # --------------------------------------------------------------------------
    # Delete the EC2 instances
    echo "Searching for EC2 instances in VPC named $vpc_name"
    instance_ids=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$vpc_name" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
        --query 'Reservations[*].Instances[*].InstanceId' --output text)

    if [[ -n "$instance_ids" ]]; then
        echo "⚠️ Terminating instances: $instance_ids"
        aws ec2 terminate-instances --instance-ids $instance_ids
        echo "⏳ Waiting for termination..."
        aws ec2 wait instance-terminated --instance-ids $instance_ids
	echo "Instances terminated!"
    else
	echo "There are no instances in VPC $vpc_name"
    fi    
    # --------------------------------------------------------------------------
    # Make sure the ENIs(Elastic Network Interface) are released before detaching and deleting the IGW
    eni_ids=$(aws ec2 describe-network-interfaces \
		  --filters "Name=vpc-id,Values=$vpc_id" \
		  --query "NetworkInterfaces[*].NetworkInterfaceId" \
		  --output text)
    echo "Find ENIs used with VPC $vpc_name: $eni_ids"
    for eni in $eni_ids; do
	alloc_id=$(aws ec2 describe-addresses \
		       --filters "Name=network-interface-id,Values=$eni" \
		       --query "Addresses[0].AllocationId" \
		       --output text 2>/dev/null)

	assoc_id=$(aws ec2 describe-addresses \
		       --filters "Name=network-interface-id,Values=$eni" \
		       --query "Addresses[0].AssociationId" \
		       --output text 2>/dev/null)
	if [[ "$assoc_id" != "None" && "$assoc_id" != "null" ]]; then
            echo "Disassociating $assoc_id from ENI $eni"
            aws ec2 disassociate-address --association-id "$assoc_id"
	fi

	if [[ "$alloc_id" != "None" && "$alloc_id" != "null" ]]; then
            echo "Releasing Elastic IP $alloc_id"
            aws ec2 release-address --allocation-id "$alloc_id"
	fi	
    done
    if [[ -z "$eni_ids" ]]; then
	echo "No ENIs with auto-assigned public IPs in VPC $vpc_name"
    fi
    # for eni in $eni_ids; do
    # 	# Get attachment ID (if any)
    # 	attachment_id=$(aws ec2 describe-network-interfaces \
    # 			    --network-interface-ids "$eni" \
    # 			    --query "NetworkInterfaces[0].Attachment.AttachmentId" \
    # 			    --output text 2>/dev/null)
    # 	echo "Attachment ID: $attachment_id"
    # 	# Detach if attached
    # 	if [[ -n "$attachment_id" ]]; then
    # 	    aws ec2 detach-network-interface --attachment-id $attachment_id && echo "$eni detached!"
    # 	fi
    # 	# Delete the ENI
    # 	aws ec2 delete-network-interface --network-interface-id "$eni" && echo "$eni deleted!"
    # done
    # --------------------------------------------------------------------------
    # Detach and delete Internet Gateways
    igw_ids=$(aws ec2 describe-internet-gateways \
		  --region "$region" \
		  --filters "Name=attachment.vpc-id,Values=$vpc_id" \
		  --filters "Name=tag:Name,Values=$igw_name" \
		  --query "InternetGateways[*].InternetGatewayId" \
		  --output text)
    for igw_id in $igw_ids; do
	echo "Detaching and deleting IGW: $igw_id"
	aws ec2 detach-internet-gateway --region "$region" --internet-gateway-id "$igw_id" --vpc-id "$vpc_id"
	aws ec2 delete-internet-gateway --region "$region" --internet-gateway-id "$igw_id" && echo "IGW deleted!"
    done
    # --------------------------------------------------------------------------
    # Delete subnets if any exist. (Consider using for loop, now hard coded)
    pub_sub1_id=$(aws ec2 describe-subnets \
		     --region "$region" \
		     --filters "Name=vpc-id,Values=$vpc_id" \
		     --filters "Name=tag:Name,Values=$pub_sub1_name" \
		     --query "Subnets[*].SubnetId" \
		     --output text)
    echo "public subnet1 ID: $pub_sub1_id"
    if [[ -n "$pub_sub1_id" ]]; then # if the public subnet1 exists
	echo "Deleting Public Subnet: $pub_sub1_id"
	aws ec2 delete-subnet --region "$region" --subnet-id "$pub_sub1_id" && echo "public subnet1 deleted!"
    fi
    priv_sub1_id=$(aws ec2 describe-subnets \
		     --region "$region" \
		     --filters "Name=vpc-id,Values=$vpc_id" \
		     --filters "Name=tag:Name,Values=$priv_sub1_name" \
		     --query "Subnets[*].SubnetId" \
		     --output text)
    echo "private subnet1 ID: $priv_sub1_id"
    if [[ -n "$priv_sub1_id" ]]; then # if the public subnet1 exists
	echo "Deleting Private Subnet: $priv_sub1_id"
	aws ec2 delete-subnet --region "$region" --subnet-id "$priv_sub1_id" && echo "private subnet1 deleted!"
    fi
    # --------------------------------------------------------------------------
    # Delete custom route tables -- Pay attention to the rtb has dependencies and cannot be deleted.(the order to delete it)
    rtb_ids=$(aws ec2 describe-route-tables \
		  --region "$region" \
		  --filters "Name=vpc-id,Values=$vpc_id" \
		  --filters "Name=tag:Name,Values=$rtb_name" \
		  --query "RouteTables[*].RouteTableId" \
		  --output text)

    for rtb_id in $rtb_ids; do
	echo "Deleting Route Table: $rtb_id"
	aws ec2 delete-route-table --region "$region" --route-table-id "$rtb_id" && \
	    echo "RouteTable ID: $rtb_id deleted!"
    done
    # --------------------------------------------------------------------------    
    # Delete non-default security groups
    sg_ids=$(aws ec2 describe-security-groups \
		 --region "$region" \
		 --filters "Name=vpc-id,Values=$vpc_id" \
		 --query "SecurityGroups[?GroupName=='Bastion Security Group'].GroupId" \
		 --output text)

    for sg_id in $sg_ids; do
	echo "Deleting Security Group: $sg_id"
	aws ec2 delete-security-group --region "$region" --group-id "$sg_id"
    done
    # --------------------------------------------------------------------------
    # delete the VPC at the end.
    aws ec2 delete-vpc --vpc-id "$vpc_id" && echo "The old VPC named $vpc_name has been deleted!"
else
    echo "No existing VPC named $vpc_name"
fi    
# Create a new VPC
vpc_id=$(aws ec2 create-vpc \
    --cidr-block $cidr_block \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=\"$vpc_name\"}]" \
    --query 'Vpc.VpcId' \
    --output text)
echo "VPC created: $vpc_id"

# Enable DNS Hostnames
aws ec2 modify-vpc-attribute \
   --vpc-id $vpc_id \
   --enable-dns-hostnames "{\"Value\":true}"

# Create Subnets
# TODO: We can assign the number of Public Subnets
net_mask_pubsub1="28"
cidr_block_pubsub1="$ip/$net_mask_pubsub1"
pub_sub1_id=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block $cidr_block_pubsub1 \
  --availability-zone $az \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$pub_sub1_name\"}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Public Subnet created: $pub_sub1_id"

# Enable Public IP on launch
aws ec2 modify-subnet-attribute \
    --subnet-id $pub_sub1_id \
    --map-public-ip-on-launch

# Create private Subnet
net_mask_privsub1="28"
start_ip_privsub="10.0.0.16"
cidr_block_privsub1="$start_ip_privsub/$net_mask_privsub1"
priv_sub1_id=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block $cidr_block_privsub1 \
  --availability-zone $az \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$priv_sub1_name\"}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Private Subnet created: $priv_sub1_id"

# Create the public Subnet 2, in another AZ
net_mask_pubsub2="28"
start_ip_pubsub2="10.0.0.32"
cidr_block_pubsub2="$start_ip_pubsub2/$net_mask_pubsub2"
pub_sub2_id=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block $cidr_block_pubsub2 \
  --availability-zone $az2 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$pub_sub2_name\"}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Public Subnet created: $pub_sub2_id"

# Enable Public IP on launch
aws ec2 modify-subnet-attribute \
    --subnet-id $pub_sub2_id \
    --map-public-ip-on-launch

# Create private Subnet
net_mask_privsub2="28"
start_ip_privsub2="10.0.0.48"
cidr_block_privsub2="$start_ip_privsub2/$net_mask_privsub2"
priv_sub2_id=$(aws ec2 create-subnet \
  --vpc-id $vpc_id \
  --cidr-block $cidr_block_privsub2 \
  --availability-zone $az2 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=\"$priv_sub2_name\"}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Private Subnet created: $priv_sub2_id"


##########################################################################################
# Creating an IGW
igwid=$(aws ec2 create-internet-gateway \
	--tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=\"$igw_name\"}]" \
--query 'InternetGateway.InternetGatewayId' \
--output text)
echo "Internet Gateway created: $igwid"

# attaching the IGW to the VPC
aws ec2 attach-internet-gateway --internet-gateway-id $igwid --vpc-id $vpc_id
echo "IGW attached: $igwid"

##########################################################################################
# Create Route Table
rtbpubid1=$(aws ec2 create-route-table \
    --vpc-id $vpc_id \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=\"$rtb_name\"}]" \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Create a Route
aws ec2 create-route \
    --route-table-id $rtbpubid1 \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $igwid \
    --no-cli-pager
# Subnet Associations
aws ec2 associate-route-table --subnet-id $pub_sub1_id --route-table-id $rtbpubid1 --no-cli-pager
echo "Public route table created and associated."

##########################################################################################
# Create Security Group for Bastion Host
bastion_sg_id=$(aws ec2 create-security-group \
  --group-name "Bastion Security Group" \
  --description "Allow SSH" \
  --vpc-id $vpc_id \
  --query 'GroupId' \
  --output text)

echo "Security Group created: $bastion_sg_id"

# Adding Ingress Rule for Bastion SG
# Using my own IP address
if [ "$use_myip" = true ]; then
    my_ip=$(curl https://checkip.amazonaws.com)
    sg_net_mask=32
else
    my_ip="0.0.0.0"
    sg_net_mask=0		# change 32 for only one ip
fi
aws ec2 authorize-security-group-ingress \
    --group-id $bastion_sg_id \
    --protocol tcp \
    --port 22 \
    --cidr $my_ip/$sg_net_mask \
    --no-cli-pager

##########################################################################################
# Create Security Group for Web Server, allow ssh and http
web_server_sg_id=$(aws ec2 create-security-group \
  --group-name "Web Server Security Group" \
  --description "Allow SSH" \
  --vpc-id $vpc_id \
  --query 'GroupId' \
  --output text)

echo "Security Group created: $web_server_sg_id"

# Adding Ingress Rule for Web Server
# Using my own IP address
if [ "$use_myip" = true ]; then
    my_ip=$(curl https://checkip.amazonaws.com)
    sg_net_mask=32
else
    my_ip="0.0.0.0"
    sg_net_mask=0		# change 32 for only one ip
fi
aws ec2 authorize-security-group-ingress \
    --group-id $web_server_sg_id \
    --protocol tcp \
    --port 22 \
    --cidr $my_ip/$sg_net_mask \
    --no-cli-pager
aws ec2 authorize-security-group-ingress \
    --group-id $web_server_sg_id \
    --protocol tcp \
    --port 80 \
    --cidr $my_ip/$sg_net_mask \
    --no-cli-pager

##########################################################################################
# Launch Bastion Host EC2
img_id=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)
echo "AMI ID: $img_id"
# img_id=ami-0ec1ab28d37d960a9 -> (Linux 2)

# Try with Amazon 2023 as well

aws ec2 run-instances \
  --image-id $img_id \
  --instance-type t3.micro \
  --subnet-id $pub_sub1_id \
  --key-name $key_name \
  --associate-public-ip-address \
  --security-group-ids $bastion_sg_id \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="Bastion Server"}]' \
  --no-cli-pager
echo "Bastion Server created!"

#########################################################################################
# Check if the DB subnet group already exists
echo "Checking for existing DB subnet group '$db_subnet_group'..."
if aws rds describe-db-subnet-groups \
  --db-subnet-group-name "$db_subnet_group" \
  --region "$region" \
  --no-cli-pager >/dev/null 2>&1; then
    echo "DB subnet group '$db_subnet_group' already exists. Skipping creation."
else
    # Create a DB subnet group
    echo "Creating DB subnet group..."
    aws rds create-db-subnet-group \
	--db-subnet-group-name $db_subnet_group \
	--db-subnet-group-description "DB subnet group for private RDS" \
	--subnet-ids "[\"$priv_sub1_id\", \"$priv_sub2_id\"]" \
	--region $region \
	--no-cli-pager
    if [ $? -eq 0 ]; then
        echo "DB subnet group created: $db_subnet_group"
    else
        echo "Failed to create DB subnet group '$db_subnet_group'."
        exit 1
    fi    
fi

# Create a security group for the RDS instance
echo "Creating security group for the RDS instance..."
RDS_sg_id=$(aws ec2 create-security-group \
  --group-name $RDS_sg_name \
  --description "Security group for RDS instance" \
  --vpc-id $vpc_id \
  --region $region \
  --query 'GroupId' \
  --output text)
echo "Security group created: $RDS_sg_id"

# Add an inbound rule to allow MySQL traffic (port 3306) from the VPC CIDR
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_sg_id \
  --protocol tcp \
  --port 3306 \
  --cidr $cidr_block \
  --region $region \
  --no-cli-pager
echo "Inbound rule added to RDS Instance security group"

# Create the RDS instance
echo "Creating RDS instance..."
aws rds create-db-instance \
  --db-instance-identifier "$RDS_identifier" \
  --db-instance-class $db_instance_class \
  --engine $db_engine \
  --engine-version $db_engine_version \
  --master-username "$master_username" \
  --master-user-password "$master_password" \
  --allocated-storage $allocated_storage \
  --db-name $db_name \
  --db-subnet-group-name $db_subnet_group \
  --vpc-security-group-ids $RDS_sg_id \
  --no-publicly-accessible \
  --region $region \
  --no-cli-pager
echo "RDS instance creation initiated. Check AWS Console for status."

# Wait for RDS instance to be available
echo "Waiting for RDS instance to be available..."
aws rds wait db-instance-available \
  --db-instance-identifier "$RDS_identifier" \
  --region $region
echo "RDS instance is now available."

aws rds modify-db-instance \
  --db-instance-identifier "$RDS_identifier" \
  --monitoring-interval 0 \
  --apply-immediately \
  --region $region \
  --no-cli-pager

#########################################################################################
# Get RDS endpoint (assuming RDS is available or check later)
rds_endpoint=$(aws rds describe-db-instances \
  --db-instance-identifier "$RDS_identifier" \
  --region $region \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text \
  --no-cli-pager 2>/dev/null || echo "RDS not ready")

# Execute the user-data when launching ec2 instance, this user-data is for Amazon Linux 2.
# Amazon linux 2023 is somewhat different
cat << EOF > user-data.sh
#!/bin/bash
sudo yum update -y	
sudo amazon-linux-extras enable php8.0 mariadb10.5
sudo yum clean metadata
sudo yum install -y php php-mysqlnd mariadb unzip httpd
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl start mariadb
sudo systemctl enable mariadb
cd /var/www/html
sudo wget https://wordpress.org/latest.zip
sudo unzip latest.zip
sudo cp -r wordpress/* .
sudo rm -rf wordpress latest.zip
sudo chown -R apache:apache /var/www/html
sudo cp wp-config-sample.php wp-config.php
sudo sed -i "s/database_name_here/wordpress/" wp-config.php
sudo sed -i "s/username_here/wpuser/" wp-config.php
sudo sed -i "s/password_here/wp-password123!/" wp-config.php
sudo sed -i "s/localhost/$rds_endpoint/" wp-config.php
sudo systemctl restart httpd
EOF

aws ec2 run-instances \
  --image-id $img_id \
  --instance-type t3.micro \
  --subnet-id $pub_sub1_id \
  --key-name $key_name \
  --associate-public-ip-address \
  --security-group-ids $web_server_sg_id \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="Web Server"}]' \
  --user-data file://user-data.sh \
  --region $region \
  --no-cli-pager
echo "Web Server created with WordPress setup!"
rm user-data.sh

# Execute SQL queries
wp_db=wordpress
wp_user=wpuser
wp_password=wp-password123!
echo "Setting up RDS database '$db_name' and user '$wp_user'..."
cat << EOF > rds_setup.sql
CREATE DATABASE $wp_db;
CREATE USER '$wp_user'@'%' IDENTIFIED BY '$wp_password';
GRANT ALL PRIVILEGES ON $wp_db.* TO '$wp_user'@'%';
FLUSH PRIVILEGES;
EOF

cat rds_setup.sql
mysql -u "$master_username" -h "$rds_endpoint" -p"$master_password" < rds_setup.sql 
if [ $? -eq 0 ]; then
    echo "Database '$db_name' and user '$wp_user' created successfully."
else
    echo "Error: Failed to execute SQL queries on RDS instance."
    cat rds_setup.sql
    rm rds_setup.sql
    exit 1
fi

rm rds_setup.sql
echo "RDS database setup complete."
