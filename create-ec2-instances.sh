#!/bin/bash

instances=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "web" "dispatch")
domain_name="lithesh.shop"
hosted_zone_id="Z01686671NYDIP6ZJB3D7"

for name in ${instances[@]}; do
if [ $name == "shipping" ] || [ $name == "mysql" ]
then 
  instance_type="t3.medium"
else
  instance_type="t3.micro"
fi
echo "Creating instance for: $name with instance type: $instance_type"

instance_id=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type $instance_type --security-group-ids sg-09c7c70bd56f0d58b --subnet-id subnet-0a3b249c1f344ef36 --query 'Instances[0].InstanceId' --output text)
echo "Instance created for: $name"
aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$name

if [ $name == "web" ]
then
    aws ec2 wait instance-running --instance-ids $instance_id
    public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PublicIpAddress]' --output text)
    ip_to_use=$public_ip
else
    private_ip=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[0].Instances[0].[PrivateIpAddress]' --output text)
    ip_to_use=$private_ip
fi

echo "creating R53 record for $name"
aws route53 change-resource-record-sets --hosted-zone-id $hosted_zone_id --change-batch '
{
    "Comment": "Creating a record set for  '$name'",
    "Changes": [{
    "Action" : "UPSERT",
    "ResourceRecordSet": {
      "Name"           :"'$name.$domain_name'",
      "Type"           :  "A",
      "TTL"            : 1 ,
      "ResourceRecords": [{
            "Value"    : " '$ip_to_use' "  
       }]
      }
    }]
}'
done    