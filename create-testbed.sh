# Ubuntu Server 18.04.
ubuntu_1804='ami-0c55b159cbfafe1f0'
# Ubuntu Server 20.04.
ubuntu_2004='ami-07efac79022b86107'

# Key name.
key_name='gatekeeper-test'

# Availability zone.
avail_zone='us-east-2b'

# VPC ID. This script assumes it is assigned 172.31.0.0/16.
vpc_id='vpc-9116def8'

#
# Create subnets.
#

man_subnet=$(sudo aws ec2 create-subnet --vpc-id ${vpc_id} --cidr-block 172.31.0.0/24 --ipv6-cidr-block 2600:1f16:354:f700::/64 --availability-zone ${avail_zone} --output text --query 'Subnet.SubnetId')

gk_front_subnet=$(sudo aws ec2 create-subnet --vpc-id ${vpc_id} --cidr-block 172.31.1.0/24 --ipv6-cidr-block 2600:1f16:354:f701::/64 --availability-zone ${avail_zone} --output text --query 'Subnet.SubnetId')

gk_back_subnet=$(sudo aws ec2 create-subnet --vpc-id ${vpc_id} --cidr-block 172.31.2.0/24 --ipv6-cidr-block 2600:1f16:354:f702::/64 --availability-zone ${avail_zone} --output text --query 'Subnet.SubnetId')

#
# Create security groups.
#

sg_ssh=$(sudo aws ec2 create-security-group \
  --group-name "SSH" \
  --description "SSH traffic" \
  --vpc-id ${vpc_id} \
  --output text \
  --query 'GroupId')

sudo aws ec2 authorize-security-group-ingress \
  --group-id ${sg_ssh} \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

sg_all=$(sudo aws ec2 create-security-group \
  --group-name "All ingress" \
  --description "All ingress traffic" \
  --vpc-id ${vpc_id} \
  --output text \
  --query 'GroupId')

sudo aws ec2 authorize-security-group-ingress \
  --group-id ${sg_all} \
  --protocol all \
  --cidr 0.0.0.0/0

sudo aws ec2 authorize-security-group-ingress \
  --group-id ${sg_all} \
  --ip-permissions IpProtocol='-1',Ipv6Ranges=[{CidrIpv6=::/0}]

#
# Create extra interfaces.
#

client_iface=$(sudo aws ec2 create-network-interface \
  --subnet-id ${gk_front_subnet} \
  --description "Client receiving interface" \
  --groups ${sg_all} \
  --private-ip-address '172.31.1.184' \
  --output text \
  --query 'NetworkInterface.NetworkInterfaceId')

sudo aws ec2 assign-ipv6-addresses \
  --network-interface-id ${client_iface} \
  --ipv6-addresses '2600:1f16:354:f701:795:5efd:5335:9876'

sudo aws ec2 modify-network-interface-attribute \
  --network-interface-id ${client_iface} \
  --no-source-dest-check

sudo aws ec2 create-tags \
  --resources ${client_iface} \
  --tags Key=Name,Value=client

gk_front_iface=$(sudo aws ec2 create-network-interface \
  --subnet-id ${gk_front_subnet} \
  --description "Gatekeeper front interface" \
  --groups ${sg_all} \
  --private-ip-address '172.31.1.43' \
  --output text \
  --query 'NetworkInterface.NetworkInterfaceId')

sudo aws ec2 assign-ipv6-addresses \
  --network-interface-id ${gk_front_iface} \
  --ipv6-addresses '2600:1f16:354:f701:0795:5efd:5335:1439'

sudo aws ec2 modify-network-interface-attribute \
  --network-interface-id ${gk_front_iface} \
  --no-source-dest-check

sudo aws ec2 create-tags \
  --resources ${gk_front_iface} \
  --tags Key=Name,Value=gk-front

gk_back_iface=$(sudo aws ec2 create-network-interface \
  --subnet-id ${gk_back_subnet} \
  --description "Gatekeeper back interface" \
  --groups ${sg_all} \
  --private-ip-address '172.31.2.102' \
  --output text \
  --query 'NetworkInterface.NetworkInterfaceId')

sudo aws ec2 assign-ipv6-addresses \
  --network-interface-id ${gk_back_iface} \
  --ipv6-addresses '2600:1f16:354:f702:0795:5efd:5335:1501'

sudo aws ec2 modify-network-interface-attribute \
  --network-interface-id ${gk_back_iface} \
  --no-source-dest-check

sudo aws ec2 create-tags \
  --resources ${gk_back_iface} \
  --tags Key=Name,Value=gk-back

#
# Create instances and attach interfaces.
#

cli_instance_id=$(sudo aws ec2 run-instances \
  --image-id ${ubuntu_2004} \
  --count 1 \
  --instance-type m5.large \
  --key-name ${key_name} \
  --security-group-ids ${sg_all} \
  --subnet-id ${man_subnet} \
  --placement AvailabilityZone=${avail_zone} \
  --associate-public-ip-address \
  --private-ip-address "172.31.0.94" \
  --user-data file://client_script.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=client}]' \
  --output text \
  --query 'Instances[*].InstanceId')

sudo aws ec2 wait instance-running --instance-ids ${cli_instance_id}

cli_iface=$(sudo aws ec2 describe-network-interfaces \
  --filters Name=attachment.instance-id,Values=${cli_instance_id} \
  --output text \
  --query 'NetworkInterfaces[0].NetworkInterfaceId')

sudo aws ec2 modify-network-interface-attribute \
  --network-interface-id ${cli_iface} \
  --no-source-dest-check

sudo aws ec2 assign-ipv6-addresses \
  --network-interface-id ${cli_iface} \
  --ipv6-addresses '2600:1f16:354:f700:0795:5efd:5335:5678'

sudo aws ec2 attach-network-interface \
  --network-interface-id ${client_iface} \
  --instance-id ${cli_instance_id} \
  --device-index 1

gk_instance_id=$(sudo aws ec2 run-instances \
  --image-id ${ubuntu_1804} \
  --count 1 \
  --instance-type m5.2xlarge \
  --key-name ${key_name} \
  --security-group-ids ${sg_ssh} \
  --subnet-id ${man_subnet} \
  --placement AvailabilityZone=${avail_zone} \
  --associate-public-ip-address \
  --user-data file://gk_script.sh \
  --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 30 } } ]" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=gk_server}]' \
  --output text \
  --query 'Instances[*].InstanceId')

sudo aws ec2 wait instance-running --instance-ids ${gk_instance_id}

sudo aws ec2 attach-network-interface \
  --network-interface-id ${gk_front_iface} \
  --instance-id ${gk_instance_id} \
  --device-index 1

sudo aws ec2 attach-network-interface \
  --network-interface-id ${gk_back_iface} \
  --instance-id ${gk_instance_id} \
  --device-index 2
