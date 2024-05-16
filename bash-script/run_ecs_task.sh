#!/bin/bash

# Command line parameters
SERVICE_NAME=$1  # The name of the task or task family
ENVIRONMENT=$2  # The environment (e.g., production, staging)
CLUSTER=$3  # The name of the ECS cluster

# Check for required parameters
if [ -z "$SERVICE_NAME" ] || [ -z "$ENVIRONMENT" ] || [ -z "$CLUSTER" ]; then
  echo "Usage: $0 <SERVICE_NAME> <ENVIRONMENT> <CLUSTER>"
  exit 1
fi

# Constant values
REGION="us-east-1"  # Specified AWS region
LOG_PREFIX="/ecs"

# Define default values based on environment
if [ "$ENVIRONMENT" == "production" ]; then
  SECURITY_GROUP=""  # Replace with the actual security group ID for production
  SUBNET=""  # Replace with the actual subnet ID for production
  VPC_ID=""  # Replace with the actual VPC ID for production
else
  SECURITY_GROUP="sg-07ee605260e72ee45"  # Replace with the actual security group ID for staging
  SUBNET="subnet-007ccb5717e938863"  # Replace with the actual subnet ID for staging
  VPC_ID="vpc-0a0d5e6731a83b9ac"  # Replace with the actual VPC ID for staging
fi

# Debug output
echo "Service Name: $SERVICE_NAME"
echo "Environment: $ENVIRONMENT"
echo "Cluster: $CLUSTER"
echo "Security Group: $SECURITY_GROUP"
echo "Subnet: $SUBNET"
echo "VPC ID: $VPC_ID"

# Verify that the subnet exists
echo "Checking if subnet exists..."
SUBNET_EXISTS=$(aws ec2 describe-subnets --subnet-ids $SUBNET --region $REGION --query 'Subnets[0].SubnetId' --output text)
if [ -z "$SUBNET_EXISTS" ]; then
  echo "Error: Subnet ID '$SUBNET' does not exist."
  exit 1
fi

# Verify that the security group exists
echo "Checking if security group exists..."
SECURITY_GROUP_EXISTS=$(aws ec2 describe-security-groups --group-ids $SECURITY_GROUP --region $REGION --query 'SecurityGroups[0].GroupId' --output text)
if [ -z "$SECURITY_GROUP_EXISTS" ]; then
  echo "Error: Security Group ID '$SECURITY_GROUP' does not exist."
  exit 1
fi

# Define the log group name
LOG_GROUP="$LOG_PREFIX/$SERVICE_NAME/$ENVIRONMENT"

# Check if the log group exists
echo "Checking if log group exists..."
LOG_GROUP_EXISTS=$(aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $REGION --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" --output text)

# Create the log group if it does not exist
if [ -z "$LOG_GROUP_EXISTS" ]; then
  echo "Creating log group: $LOG_GROUP"
  aws logs create-log-group --log-group-name $LOG_GROUP --region $REGION
else
  echo "Log group already exists: $LOG_GROUP"
fi

# Fetching the latest revision of the task definition
echo "Fetching the latest task definition..."
TASK_DEFINITION=$(aws ecs list-task-definitions --family-prefix $SERVICE_NAME --sort DESC --query 'taskDefinitionArns[0]' --output text --region $REGION)
if [ -z "$TASK_DEFINITION" ]; then
  echo "Error: Could not retrieve the latest task definition for service: $SERVICE_NAME"
  exit 1
fi

echo "Using task definition: $TASK_DEFINITION"

# Running the ECS task
echo "Running the ECS task..."
RUN_TASK_OUTPUT=$(aws ecs run-task --cluster $CLUSTER --launch-type FARGATE --task-definition $TASK_DEFINITION --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" --region $REGION)
if [ $? -ne 0 ]; then
  echo "Error: Failed to run task"
  echo "RUN_TASK_OUTPUT: $RUN_TASK_OUTPUT"
  exit 1
fi

# Extracting the Task ARN from the output
TASK_ARN=$(echo $RUN_TASK_OUTPUT | jq -r '.tasks[0].taskArn')
if [ -z "$TASK_ARN" ]; then
  echo "Error: Task ARN not found in the output"
  echo "RUN_TASK_OUTPUT: $RUN_TASK_OUTPUT"
  exit 1
fi

# Constructing the log group link
LOG_GROUP_LINK="https://console.aws.amazon.com/cloudwatch/home?region=$REGION#logsV2:log-groups/log-group/$LOG_GROUP"

# Outputting the Task ARN and log group link
echo "Task ARN: $TASK_ARN"
echo "Log Group Link: $LOG_GROUP_LINK"

