#!/bin/bash

# Command line parameters
SERVICE_NAME=$1  # The name of the task or task family
ENVIRONMENT=$2  # The environment (e.g., production, staging)

# Check for required parameters
if [ -z "$SERVICE_NAME" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <SERVICE_NAME> <ENVIRONMENT>"
  exit 1
fi

# Constant values
REGION="us-east-1"  
LOG_PREFIX="/ecs-cluster"

# Define default values based on environment
case $ENVIRONMENT in
  production)
    CLUSTER="production" # Cluster name 
    SECURITY_GROUP="sg-xxxxxx"  # Actual security group ID for production
    PRIMARY_SUBNET="subnet-xxxxxx"  # Actual primary subnet ID for production
    SECONDARY_SUBNET="subnet-xxxxxx"  # Actual secondary subnet ID for production
    VPC_ID="vpc-xxxxxx"  # Actual VPC ID for production
    ;;
  staging)
    CLUSTER="staging" # Cluster name
    SECURITY_GROUP="sg-09744c887ea95e783"  # Actual security group ID for staging
    PRIMARY_SUBNET="subnet-04fbbc86ea80f6934"  # Actual primary subnet ID for staging
    SECONDARY_SUBNET="subnet-081dee713da1a43ab"  # Actual secondary subnet ID for staging
    VPC_ID="vpc-0dd5cffeb8c4d7d78"  # Actual VPC ID for staging
    ;;
  *)
    echo "Invalid environment specified. Use 'production' or 'staging'."
    exit 1
    ;;
esac

# Debug output
echo "Service Name: $SERVICE_NAME"
echo "Environment: $ENVIRONMENT"
echo "Cluster: $CLUSTER"
echo "Security Group: $SECURITY_GROUP"
echo "Primary Subnet: $PRIMARY_SUBNET"
echo "Secondary Subnet: $SECONDARY_SUBNET"
echo "VPC ID: $VPC_ID"

# Function to check if a subnet exists
function check_subnet {
  SUBNET_ID=$1
  aws ec2 describe-subnets --subnet-ids $SUBNET_ID --region $REGION --query 'Subnets[0].SubnetId' --output text
}

# Verify subnets
for SUBNET in $PRIMARY_SUBNET $SECONDARY_SUBNET; do
  echo "Checking if subnet $SUBNET exists..."
  if ! check_subnet $SUBNET; then
    echo "Warning: Subnet $SUBNET does not exist or is not available."
    exit 1
  fi
done

# Verify security group
echo "Checking if security group exists..."
if ! aws ec2 describe-security-groups --group-ids $SECURITY_GROUP --region $REGION --query 'SecurityGroups[0].GroupId' --output text; then
  echo "Error: Security Group ID '$SECURITY_GROUP' does not exist."
  exit 1
fi

# Define the log group name
LOG_GROUP="${LOG_PREFIX}/${SERVICE_NAME}"

# Check if the log group exists
echo "Checking if log group exists..."
if ! aws logs describe-log-groups --log-group-name $LOG_GROUP --region $REGION --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" --output text; then
  echo "Creating log group: $LOG_GROUP"
  if ! aws logs create-log-group --log-group-name $LOG_GROUP --region $REGION; then
    echo "Failed to create log group."
    exit 1
  fi
else
  echo "Log group already exists: $LOG_GROUP"
fi

# Fetching and running task
echo "Fetching the latest task definition..."
if TASK_DEFINITION=$(aws ecs list-task-definitions --family-prefix $SERVICE_NAME --sort DESC --query 'taskDefinitionArns[0]' --output text --region $REGION); then
  echo "Using task definition: $TASK_DӘFINITION"
  echo "Running the ECS task..."
  if ! RUN_TASK_OUTPUT=$(aws ecs run-task --cluster $CLUSTER --launch-type FARGATE --task-definition $TASK_DEFINITION --network-configuration "awsvpcConfiguration={subnets=[$PRIMARY_SUBNET],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" --region $REGION); then
    echo "Error: Failed to run task"
    echo "RUN_TASK_OUTPUT: $RUN_TASK_OUTPUT"
    exit 1
  fi
  TASK_ARN=$(echo $RUN_TASK_OUTPUT | jq -r '.tasks[0].taskArn')
  echo "Task ARN: $TASK_ARN"
else
  echo "Error: Could not retrieve the latest task definition for service: $SERVICE_NAME"
  exit 1
fi

# Additional task monitoring and log fetching logic here...

