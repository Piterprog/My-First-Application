#!/bin/bash

# Command line parameters
SERVICE_NAME=$1  # The name of the ECS task or service
ENVIRONMENT=$2   # The deployment environment (e.g., production, staging)

# Check for required parameters
if [ -z "$SERVICE_NAME" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <SERVICE_NAME> <ENVIRONMENT>"
  exit 1
fi


# Configuration based on environment
REGION="us-east-1"

# Define default values based on environment
if [ "$ENVIRONMENT" == "production" ]; then
  CLUSTER="production"
  SECURITY_GROUP=""  # Replace with the actual security group ID for production
  PRIMARY_SUBNET=""  # Replace with the primary subnet ID for production
  SECONDARY_SUBNET=""  # Replace with the secondary subnet ID for production
  VPC_ID=""  # Replace with the actual VPC ID for production
elif [ "$ENVIRONMENT" == "staging" ]; then
  CLUSTER="staging"
  SECURITY_GROUP="sg-09744c887ea95e783"  # Replace with the actual security group ID for staging
  PRIMARY_SUBNET="subnet-04fbbc86ea80f6934"  # Replace with the primary subnet ID for staging
  SECONDARY_SUBNET="subnet-081dee713da1a43ab"  # Replace with the secondary subnet ID for staging
  VPC_ID="vpc-0dd5cffeb8c4d7d78"  # Replace with the actual VPC ID for staging
else
  echo "Invalid environment specified. Use 'production' or 'staging'."
  exit 1
fi

# Debug output
echo "Service Name: $SERVICE_NAME"
echo "Environment: $ENVIRONMENT"
echo "Cluster: $CLUSTER"
echo "Security Group: $SECURITY_GROUP"
echo "Primary Subnet: $PRIMARY_SUBNET"
echo "Secondary Subnet: $SECONDARY_SUBNET"
echo "VPC ID: $VPC_ID"

# Flag to track errors
error_flag=0

# Function to check if a resource exists
check_resource() {
  RESOURCE_TYPE=$1
  RESOURCE_ID=$2
  aws $RESOURCE_TYPE describe --region $REGION --$RESOURCE_TYPE-ids $RESOURCE_ID > /dev/null 2>&1
}

# Check if VPC exists
check_resource "ec2 describe-vpcs" $VPC_ID
if [ $? -ne 0 ]; then
  echo "Error: VPC with ID $VPC_ID not found."
  error_flag=1
else
  echo "VPC with ID $VPC_ID exists."
fi

# Check if primary subnet exists
check_resource "ec2 describe-subnets" $PRIMARY_SUBNET
if [ $? -ne 0 ]; then
  echo "Primary subnet with ID $PRIMARY_SUBNET not found. Trying secondary subnet..."
  PRIMARY_SUBNET=$SECONDARY_SUBNET
else
  echo "Using primary subnet: $PRIMARY_SUBNET"
fi

# Check if secondary subnet exists
check_resource "ec2 describe-subnets" $SECONDARY_SUBNET
if [ $? -ne 0 ]; then
  echo "Secondary subnet with ID $SECONDARY_SUBNET not found. Using primary subnet..."
fi

# Check if security group exists
check_resource "ec2 describe-security-groups" $SECURITY_GROUP
if [ $? -ne 0 ]; then
  echo "Error: Security group with ID $SECURITY_GROUP not found."
  error_flag=1
else
  echo "Security group with ID $SECURITY_GROUP exists."
fi

# Exit if there was an error
if [ $error_flag -ne 0 ]; then
  exit 1
fi

# Continue with the rest of the script...

