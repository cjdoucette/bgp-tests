# VPC ID.
vpc_id='vpc-9116def8'

#
# Delete instances.
#

client_instance=$(sudo aws ec2 describe-instances \
    --filters 'Name=tag:Name,Values=client' \
    --output text \
    --query 'Reservations[*].Instances[*].InstanceId')
sudo aws ec2 terminate-instances --instance-ids ${client_instance}

gk_server_instance=$(sudo aws ec2 describe-instances \
    --filters 'Name=tag:Name,Values=gk_server' \
    --output text \
    --query 'Reservations[*].Instances[*].InstanceId')
sudo aws ec2 terminate-instances --instance-ids ${gk_server_instance}

sudo aws ec2 wait instance-terminated --instance-ids ${client_instance}
sudo aws ec2 wait instance-terminated --instance-ids ${gk_server_instance}

#
# Delete extra network interfaces.
#

client_iface=$(sudo aws ec2 describe-network-interfaces \
  --filters "Name=description,Values=Client receiving interface" \
  --output text \
  --query 'NetworkInterfaces[*].NetworkInterfaceId')
sudo aws ec2 delete-network-interface --network-interface-id ${client_iface}

gk_front_iface=$(sudo aws ec2 describe-network-interfaces \
  --filters "Name=description,Values=Gatekeeper front interface" \
  --output text \
  --query 'NetworkInterfaces[*].NetworkInterfaceId')
sudo aws ec2 delete-network-interface --network-interface-id ${gk_front_iface}

gk_back_iface=$(sudo aws ec2 describe-network-interfaces \
  --filters "Name=description,Values=Gatekeeper back interface" \
  --output text \
  --query 'NetworkInterfaces[*].NetworkInterfaceId')
sudo aws ec2 delete-network-interface --network-interface-id ${gk_back_iface}

#
# Delete subnets.
#

man_subnet=$(sudo aws ec2 describe-subnets \
  --filters "Name=cidr-block,Values=172.31.0.0/24" \
  --output text \
  --query 'Subnets[*].SubnetId')
sudo aws ec2 delete-subnet --subnet-id ${man_subnet}

gk_front_subnet=$(sudo aws ec2 describe-subnets \
  --filters "Name=cidr-block,Values=172.31.1.0/24" \
  --output text \
  --query 'Subnets[*].SubnetId')
sudo aws ec2 delete-subnet --subnet-id ${gk_front_subnet}

gk_back_subnet=$(sudo aws ec2 describe-subnets \
  --filters "Name=cidr-block,Values=172.31.2.0/24" \
  --output text \
  --query 'Subnets[*].SubnetId')
sudo aws ec2 delete-subnet --subnet-id ${gk_back_subnet}

#
# Delete security groups.
#

sudo aws ec2 delete-security-group --group-name "SSH"
sudo aws ec2 delete-security-group --group-name "All ingress"
