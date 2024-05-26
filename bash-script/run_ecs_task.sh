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
LOG_PREFIX="/ecs"

# Define default values based on environment
if [ "$ENVIRONMENT" == "production" ]; then
  CLUSTER="production" # Cluster name 
  SECURITY_GROUP=""  # Replace with the actual security group ID for production
  PRIMARY_SUBNET=""  # Replace with the primary subnet ID for production
  SECONDARY_SUBNET=""  # Replace with the secondary subnet ID for production
  VPC_ID=""  # Replace with the actual VPC ID for production
else
  CLUSTER="staging" # Cluster name
  SECURITY_GROUP="sg-0b8d65e68add439fa"  # Replace with the actual security group ID for staging
  PRIMARY_SUBNET="subnet-03bcc3211dec8169e"  # Replace with the primary subnet ID for staging
  SECONDARY_SUBNET="subnet-07db11fbbad6729a5"  # Replace with the secondary subnet ID for staging
  VPC_ID="vpc-017a0945b84cbbf82"  # Replace with the actual VPC ID for staging
fi

# Debug output
echo "Service Name: $SERVICE_NAME"
echo "Environment: $ENVIRONMENT"
echo "Cluster: $CLUSTER"
echo "Security Group: $SECURITY_GROUP"
echo "Primary Subnet: $PRIMARY_SUBNET"
echo "Secondary Subnet: $SECONDARY_SUBNET"
echo "VPC ID: $VPC_ID"

# Function to check if a subnet exists
check_subnet() {
  SUBNET_ID=$1
  aws ec2 describe-subnets --subnet-ids $SUBNET_ID --region $REGION --query 'Subnets[0].SubnetId' --output text
}

# Verify that the primary subnet exists
echo "Checking if primary subnet exists..."
PRIMARY_SUBNET_EXISTS=$(check_subnet $PRIMARY_SUBNET)
if [ -n "$PRIMARY_SUBNET_EXISTS" ]; then
  SUBNET=$PRIMARY_SUBNET
  echo "Using primary subnet: $PRIMARY_SUBNET"
else
  echo "Warning: Primary subnet '$PRIMARY_SUBNET' does not exist or is not available."
  
  # Verify that the secondary subnet exists
  echo "Checking if secondary subnet exists..."
  SECONDARY_SUBNET_EXISTS=$(check_subnet $SECONDARY_SUBNET)
  if [ -n "$SECONDARY_SUBNET_EXISTS" ]; then
    SUBNET=$SECONDARY_SUBNET
    echo "Using secondary subnet: $SECONDARY_SUBNET"
  else
    echo "Error: Neither primary nor secondary subnets are valid or available."
    exit 1
  fi
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

# Wait for the task to reach a stable state
echo "Waiting for the task to reach a stable state..."
while true; do
  TASK_STATUS=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $REGION --query 'tasks[0].lastStatus' --output text)
  echo "Current Task Status: $TASK_STATUS"
  if [ "$TASK_STATUS" == "RUNNING" ] || [ "$TASK_STATUS" == "STOPPED" ]; then
    break
  fi
  sleep 10
done

# Fetch the task status
echo "Final Task Status: $TASK_STATUS"

# Fetch the task details for further diagnostics
echo "Fetching the task details..."
TASK_DETAILS=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $REGION --query 'tasks[0]')
echo "Task Details: $TASK_DETAILS"

# Fetch the task stop reason if task is stopped
if [ "$TASK_STATUS" == "STOPPED" ]; then
  STOP_REASON=$(aws ecs describe-tasks --cluster $CLUSTER --tasks $TASK_ARN --region $REGION --query 'tasks[0].stopReason' --output text)
  echo "Task Stop Reason: $STOP_REASON"
fi

# Extract log stream name from task details
CONTAINER_DETAILS=$(echo $TASK_DETAILS | jq -r '.containers[0]')
CONTAINER_NAME=$(echo $CONTAINER_DETAILS | jq -r '.name')
CONTAINER_RUNTIME_ID=$(echo $CONTAINER_DETAILS | jq -r '.runtimeId')
LOG_STREAM_NAME=$(echo $CONTAINER_DETAILS | jq -r '.logConfiguration.options["awslogs-stream-prefix"]')"/"$CONTAINER_RUNTIME_ID

# Wait for log stream to be available
echo "Waiting for log stream to be available..."
sleep 30

# Check if log stream exists
LOG_STREAM_EXISTS=$(aws logs describe-log-streams --log-group-name $LOG_GROUP --log-stream-name-prefix $LOG_STREAM_NAME --region $REGION --query "logStreams[?logStreamName=='$LOG_STREAM_NAME'].logStreamName" --output text)

if [ -z "$LOG_STREAM_EXISTS" ]; then
  echo "Error: Log stream '$LOG_STREAM_NAME' does not exist."
  exit 1
fi

# Fetch the container logs
echo "Fetching container logs for container: $LOG_STREAM_NAME"
aws logs get-log-events --log-group-name $LOG_GROUP --log-stream-name $LOG_STREAM_NAME --region $REGION --limit 10 --query 'events[*].message' --output text



