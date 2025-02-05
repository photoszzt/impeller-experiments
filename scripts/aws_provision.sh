#!/bin/bash

AWS_REGION="us-east-2"
PLACEMENT_GROUP_NAME="impeller-experiments"
SECURITY_GROUP_NAME="impeller"

# Create placement group
aws --output text --region $AWS_REGION ec2 create-placement-group \
	--group-name $PLACEMENT_GROUP_NAME --strategy cluster

# Create security group
SECURITY_GROUP_ID=$(
	aws --output text --region $AWS_REGION ec2 create-security-group \
		--group-name $SECURITY_GROUP_NAME --description "impeller experiments"
)
SECURITY_GROUP_ID=$(aws --region $AWS_REGION ec2 describe-security-groups --group-name $SECURITY_GROUP_NAME --query 'SecurityGroups[*].[GroupId]' --output text)

# Allow all internal traffic within the newly create security group
aws --output text --region $AWS_REGION ec2 authorize-security-group-ingress \
	--group-id $SECURITY_GROUP_ID \
	--ip-permissions "IpProtocol=-1,FromPort=-1,ToPort=-1,UserIdGroupPairs=[{GroupId=$SECURITY_GROUP_ID}]"

LOCAL_IP=$(ip addr | grep  'state UP' -A4 | grep "inet " |awk '{print $2}' | cut -f1 -d'/')
echo "console machine ip is $LOCAL_IP"

# Allow SSH traffic from current machine to the newly create security group
aws --output text --region $AWS_REGION ec2 authorize-security-group-ingress \
	--group-id $SECURITY_GROUP_ID \
	--ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$LOCAL_IP/32}]"
