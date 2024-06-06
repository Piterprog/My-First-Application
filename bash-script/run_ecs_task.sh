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

# Check if VPC exists
if ! aws ec2 describe-vpcs --vpc-ids $VPC_ID --region $REGION > /dev/null 2>&1; then
  echo "Error: VPC with ID $VPC_ID not found."
  exit 1
fi
echo "VPC with ID $VPC_ID exists."

# Check if primary subnet exists
if ! aws ec2 describe-subnets --subnet-ids $PRIMARY_SUBNET --region $REGION > /dev/null 2>&1; then
  echo "Primary subnet with ID $PRIMARY_SUBNET not found. Trying secondary subnet..."
  PRIMARY_SUBNET=$SECONDARY_SUBNET
fi
echo "Using primary subnet: $PRIMARY_SUBNET"

# Check if secondary subnet exists
if ! aws ec2 describe-subnets --subnet-ids $SECONDARY_SUBNET --region $REGION > /dev/null 2>&1; then
  echo "Secondary subnet with ID $SECONDARY_SUBNET not found. Using primary subnet..."
fi

# Check if security group exists
if ! aws ec2 describe-security-groups --group-ids $SECURITY_GROUP --region $REGION > /dev/null 2>&1; then
  echo "Error: Security group with ID $SECURITY_GROUP not found."
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
echo "Using task definition: $TASK_DEFINITION"

# Running the ECS task
echo "Running the ECS task..."
RUN_TASK_OUTPUT=$(aws ecs run-task --cluster $CLUSTER --launch-type FARGATE --task-definition $TASK_DEFINITION --network-configuration "awsvpcConfiguration={subnets=[$PRIMARY_SUBNET],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" --region $REGION)
TASK_ARN=$(echo $RUN_TASK_OUTPUT | jq -r '.tasks[0].taskArn')
echo "Task ARN: $TASK_ARN"

# Extract log group and stream names from task definition
LOG_GROUP=$(echo $RUN_TASK_OUTPUT | jq -r '.tasks[0].containers[0].logConfiguration.options["awslogs-group"]')
LOG_STREAM_PREFIX=$(echo $RUN_TASK_OUTPUT | jq -r '.tasks[0].containers[0].logConfiguration.options["awslogs-stream-prefix"]')

# Get the full log stream name
LOG_STREAM_NAME="${LOG_STREAM_PREFIX}/${SERVICE_NAME}/${TASK_ARN}"

# Output the log stream name
echo "Log Stream Name: $LOG_STREAM_NAME"

# Output the task definition
echo "Task Definition:"
aws ecs describe-task-definition --task-definition $TASK_DEFINITION --region $REGION

# Create the link to the log group
LOG_GROUP_LINK="https://$REGION.console.aws.amazon.com/cloudwatch/home?region=$REGION#logsV2:log-groups/log-group/$LOG_GROUP/log-events/$LOG_STREAM_NAME"
echo "Log Group Link: $LOG_GROUP_LINK"
