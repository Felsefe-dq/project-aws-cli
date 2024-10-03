 #!/bin/bash

vpc_cidr="10.0.0.0/16"
subnet_cidr1="10.0.1.0/24"
subnet_cidr2="10.0.2.0/24"
subnet_cidr3="10.0.3.0/24"
region="us-east-1"
az1="us-east-1a"
az2="us-east-1b"
az3="us-east-1c"

vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --region $region --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=kaizen}]' --query Vpc.VpcId --output text)

# Create first subnet in AZ "us-east-1a"

subnet1=$(aws ec2 create-subnet --vpc-id $vpc_id  --cidr-block $subnet_cidr1  --availability-zone $az1 --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=subnet1}]' --query Subnet.SubnetId --output text)

# Create second subnet in AZ "us-east-1b"

subnet2=$(aws ec2 create-subnet --vpc-id $vpc_id  --cidr-block $subnet_cidr2  --availability-zone $az2 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet2}]')

# Create third subnet in AZ "us-east-1c"

subnet3=$(aws ec2 create-subnet --vpc-id $vpc_id  --cidr-block $subnet_cidr3  --availability-zone $az3  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=subnet3}]')

# Create an Internet Gateway

igw=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)

# Attach the Internet Gateway with the VPC.


aws ec2 attach-internet-gateway --internet-gateway-id $igw  --vpc-id $vpc_id


#Create a custom  Route Table


rt=$(aws ec2 create-route-table --vpc-id $vpc_id  --query RouteTable.RouteTableId --output text)


# Add a route (Traffic destined to the internet will go via the internet gateway

aws ec2 create-route --route-table-id $rt  --destination-cidr-block 0.0.0.0/0 --gateway-id $igw


#Tag the Route Table

aws ec2 create-tags --resources $rt  --tags Key=Name,Value=kaizen_rt

#Associate the Route Table with the Subnet

aws ec2 associate-route-table --subnet-id $subnet1  --route-table-id $rt

# Create a new Security Group
 
sg=$(aws ec2 create-security-group --group-name Kaizen --description "Kaizen Group Project" --vpc-id $vpc_id  --tag-specifications 'ResourceType=security-group, Tags=[{Key=Name,Value=custom-sg}]' --query GroupId --output text)


# Open the SSH port(22) in the ingress rules

aws ec2 authorize-security-group-ingress --group-id $sg  --protocol tcp --port 22 --cidr 0.0.0.0/0


# Open the SSH port(80) in the ingress rules

aws ec2 authorize-security-group-ingress --group-id $sg  --protocol tcp --port 80  --cidr 0.0.0.0/0

# Import the key pair


aws ec2 import-key-pair --key-name "ProjectKeyPair" --public-key-material fileb://~/.ssh/id_rsa.pub







# Create the EC2 instance


aws=$(aws ec2 run-instances --image-id ami-087c17d1fe0178315 --count 1 --instance-type t2.micro --key-name ProjectKeyPair  --security-group-ids $sg  --subnet-id $subnet1  --associate-public-ip-address --key-name 'ProjectKeyPair'  --tag-specifications  'ResourceType=instance,Tags=[{Key=Name,Value=Project-EC2}]' --query InstanceID --output text)




# Get the Public IP of the EC2 instance


ip=$(aws ec2 describe-instances --query "Reservations[*].Instances[*].{InstanceID:InstanceId,State:State.Name,Address:PublicIpAddress}" --filters Name=tag:Name,Values=Project-EC2 --output text)



















