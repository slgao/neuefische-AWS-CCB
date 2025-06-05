# WordPress AWS Deployment

This project sets up an AWS infrastructure to deploy a WordPress server using the AWS CLI. The architecture includes a VPC with four subnets (two public and two private), a bastion host, a web server EC2 instance running WordPress, and an RDS MySQL instance in the private subnets. The scripts automate the creation of the infrastructure and provide a way to connect to the EC2 instances securely.

## Architecture Overview

The project creates the following AWS resources in the `us-west-2` region:
- **VPC** (`wp_vpc`): A Virtual Private Cloud with CIDR block `10.0.0.0/26` (64 IP addresses).
- **Subnets**:
  - Two public subnets (`Public Subnet 1` and `Public Subnet 2`) in availability zones `us-west-2a` and `us-west-2b` for hosting EC2 instances.
  - Two private subnets (`Private Subnet 1` and `Private Subnet 2`) in `us-west-2a` and `us-west-2b` for the RDS instance.
- **Internet Gateway** (`MY-IGW`): Attached to the VPC for public subnet internet access.
- **Route Table** (`Public Route Table`): Routes traffic from public subnets to the internet gateway.
- **Security Groups**:
  - `Bastion Security Group`: Allows SSH (port 22) from any IP (configurable).
  - `Web Server Security Group`: Allows SSH (port 22) from any IP (configurable).
  - `RDS-Security-Group`: Allows MySQL (port 3306) from the VPC CIDR.
- **EC2 Instances**:
  - **Bastion Server**: An EC2 instance (`t3.micro`, Amazon Linux 2) in a public subnet for secure access.
  - **Web Server**: An EC2 instance (`t3.micro`, Amazon Linux 2) in a public subnet to host WordPress.
- **Key Pair** (`wp-key`): Used for SSH access to EC2 instances, saved as `labsuser.pem`.
- **RDS Instance** (`RDS-Instance`): A MySQL 8.0 database (`db.t3.micro`, 100 GB storage) in the private subnets, using the `DB-Subnet-Group`.
- **DB Subnet Group** (`DB-Subnet-Group`): Groups the private subnets for RDS.

The WordPress application on the web server will connect to the RDS instance for database operations.

## Prerequisites

- **AWS CLI**: Installed and configured with valid credentials (`aws configure`) and permissions for:
  - `ec2:Create*`, `ec2:Describe*`, `ec2:Delete*`, `ec2:Modify*`, `ec2:Associate*`, `ec2:AuthorizeSecurityGroupIngress`
  - `rds:Create*`, `rds:Describe*`, `rds:Modify*`
- **Bash Environment**: Linux or macOS (or WSL on Windows).
- **SSH Client**: For connecting to EC2 instances.
- **Permissions for `labsuser.pem`**: Ensure the key file has `chmod 400` permissions.
- **Optional Tools(in the future)**:
  - `boxes` for enhanced ASCII diagram output (`sudo apt install boxes` or `brew install boxes`).
  - `jq` for JSON parsing (`sudo apt install jq` or `brew install jq`).

## Setup Instructions

1. **Clone or Download the Project**
   - Save the scripts (`wordpress_server_setup.sh` and `ec2_connect.sh`) to a project folder.

2. **Make Scripts Executable**
   ```bash
   chmod +x wordpress_server_setup.sh ec2_connect.sh
   ```

3. **Review Configuration**
   - Open `wordpress_server_setup.sh` and verify variables:
     - `region="us-west-2"`: AWS region.
     - `key_name="wp-key"`, `key_file="labsuser.pem"`: Key pair for EC2 access.
     - `RDS_identifier="RDS-Instance"`, `db_subnet_group="DB-Subnet-Group"`: RDS settings.
     - `master_username`, `master_password`, `db_name`: RDS credentials and database name.
     - `my_ip="0.0.0.0"`, `sg_net_mask=0`: Security group ingress (restrict to your IP for security, e.g., `x.x.x.x/32`).
   - Update CIDR blocks or subnet configurations if needed.

4. **Run the Setup Script**
   ```bash
   ./wordpress_server_setup.sh
   ```
   - The script:
     - Checks for and deletes an existing VPC named `wp_vpc` (including dependencies like EC2 instances, subnets, and internet gateways) -- still beta version.
     - Creates a new VPC, subnets, internet gateway, route table, security groups, EC2 instances (bastion and web server), key pair, DB subnet group, and RDS instance.
     - Initiates RDS creation but does not wait for availability (commented wait command recommended to avoid delays).
   - **Note**: The RDS instance may take 5–15 minutes to become available due to initial backup. Check status with:
     ```bash
     aws rds describe-db-instances --db-instance-identifier "RDS-Instance" --region us-west-2 --no-cli-pager --query 'DBInstances[0].DBInstanceStatus'
     ```

5. **Install WordPress on the Web Server (this part is also integrated in the bash script)**
   - Get the web server’s public IP:
     ```bash
     aws ec2 describe-instances --filters "Name=tag:Name,Values=Web Server" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].PublicIpAddress' --output text
     ```
   - Connect to the web server using `ec2_connect.sh`:
     ```bash
     ./ec2_connect.sh <web-server-public-ip>
     ```
   - On the EC2 instance, install and configure WordPress:
     ```bash
	 <!-- Update the package index -->
     sudo yum update -y
	 <!-- Install all required packages -->
     sudo amazon-linux-extras enable php8.0 mariadb10.5
	 sudo yum clean metadata
	 sudo yum install -y php php-mysqlnd mariadb unzip httpd
	 <!-- Start and enable the Apache web server -->
     sudo systemctl start httpd
     sudo systemctl enable httpd
	 <!-- Start and enable the MariaDB service: -->
	 sudo systemctl start mariadb
     sudo systemctl enable mariadb
	 <!-- Download and setup Wordpress -->
	 cd /var/www/html
	 sudo wget https://wordpress.org/latest.zip
	 sudo unzip latest.zip
	 sudo cp -r wordpress/* .
	 sudo rm -rf wordpress latest.zip
     sudo chown -R apache:apache /var/www/html
     ```
    - Connect to your RDS instance:
     - Get the RDS endpoint:
       ```bash
       aws rds describe-db-instances --db-instance-identifier "RDS-Instance" --region us-west-2 --no-cli-pager --query 'DBInstances[0].Endpoint.Address'
	   mysql -u admin -h <rds-instance-endpoint> -pwp-password123!
       ```
       ```sql
       CREATE DATABASE wordpress;
       CREATE USER 'wpuser'@'%' IDENTIFIED BY 'wp-password123!';
       GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
       FLUSH PRIVILEGES;
	   ```
   - Configure WordPress to connect to the RDS instance:
     - Generate the `wp-config.php` file:
     ```bash
     sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
	 ```
     - Edit `sudo vim /var/www/html/wp-config.php` with the RDS endpoint, `wordpress`, `wpuser`, and `wp-password123!`.

6. **Access WordPress**
   - Open the web server’s public IP in a browser to complete the WordPress setup.
   - Restrict security group ingress (`my_ip`) to your actual IP for production.

## Connecting to Instances

- Use `ec2_connect.sh` to SSH into the bastion or web server:
  ```bash
  ./ec2_connect.sh <ec2-public-ip>
  ```
- The script ensures `labsuser.pem` has correct permissions (`chmod 400`) and connects using `ssh -i labsuser.pem ec2-user@<ec2-public-ip>`.

## Scripts

- **`wordpress_server_setup.sh`**:
  - Automates the creation of the AWS infrastructure.
  - Checks for existing resources (key pair, DB subnet group, VPC) and deletes/recreates the VPC if needed.
  - Deploys a bastion host, web server, and RDS instance.
  - **Note**: The RDS wait command is included but may cause delays due to initial backups. Comment out the `aws rds wait db-instance-available` line to skip waiting, and check status manually.

- **`ec2_connect.sh`**:
  - Connects to an EC2 instance using the `labsuser.pem` key file.
  - Requires the instance’s public IP as an argument.

## Notes

- **Security**: The security groups allow SSH from `0.0.0.0/0` for simplicity (some restrictions with my VPN at the moment). For production, restrict to your IP (e.g., `x.x.x.x/32`).
- **RDS Wait Time**: The RDS creation may take 5–15 minutes due to initial backups. To skip waiting, comment out:
  ```bash
  # aws rds wait db-instance-available \
  #   --db-instance-identifier "$RDS_identifier" \
  #   --region "$region"
  ```
  Check status manually as shown above.
- **Cleanup**: The script deletes an existing VPC named `wp_vpc` and its dependencies. Ensure no critical resources use this name.
- **Password Security**: The RDS password (`wp-password123!`) is hardcoded. Store it securely (e.g., AWS Secrets Manager) for production.
- **Region**: Defaults to `us-west-2`. Update `region` in the script or AWS CLI config if needed.

## Troubleshooting

- **RDS Not Available**: If WordPress cannot connect to RDS, verify the RDS status (`available`) and endpoint. Ensure the security group allows port 3306 from the web server.
- **SSH Connection Fails**: Check `labsuser.pem` permissions (`chmod 400`) and security group ingress rules.
- **VPC Deletion Errors**: If the VPC cannot be deleted, manually check for dependencies (e.g., ENIs, NAT gateways) in the AWS Console.

## Future Improvements

- Move the web server to a private subnet and use a load balancer for public access.
- Enable RDS automated backups after creation.
- Use AWS Secrets Manager for RDS credentials.
- Add a script to automate WordPress installation on the web server.
