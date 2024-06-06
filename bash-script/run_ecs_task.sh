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
LOG_GROUP="${LOG_PREFIX}/$SERVICE_NAME"

# Define default values based on environment
if [ "$ENVIRONMENT" == "production" ]; then
  CLUSTER="production"
  SECURITY_GROUP=""
  PRIMARY_SUBNET=""
  SECONDary_SUBNET=""
  VPC_ID=""
elif [ "$ENVIRONMENT" == "staging" ]; then
  CLUSTER="staging"
  SECURITY_GROUP="sg-09744c887ea95e783"
  PRIMARY_SUBNET="subnet-04fbbc86ea80f6934"
  SECONDARY_SUBNET="subnet-081dee713da1a43ab"
  VPC_ID="vpc-0dd5cffeb8c4d7d78"
else
  echo "Invalid environment specified. Use 'production' or 'staging'."
  exit 1
fi

# Check if the log group exists
echo "Checking if log group exists..."
LOG_GROUP_EXISTS=$(aws logs describe-log-groups --log-group-name "$LOG_GROUP" --region $REGION --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" --output text)

if [ -z "$LOG_GROUP_EXISTS" ]; then
  echo "Log group does not exist. Creating log group: $LOG_GROUP"
  if ! aws logs create-log-group --log-group-name "$LOG_GROUP" --region $REGION; then
    echo "Failed to create log group."
    exit 1
  fi
else
  echo "Log group already exists: $LOG_GROUP"
fi

# Fetching the latest revision of the task definition
echo "Fetching the latest task definition..."
TASK_DEFINITION=$(aws ecs list-task-definitions --family-prefix $SERVICE_NAME --sort DESC --query 'taskDefinitionArns[0]' --output text --region $REGION)
if [ -z "$TASK_DEFINITION" ]; then
  echo "Error: Could not retrieve the latest task definition for service: $SERVICE_END"
  exit 1
fi

echo "Using task definition: $TASK_DEFINITION"

# Running the ECS task
echo "Running the ECS task..."
RUN_TASK_OUTPUT=$(aws ecs run-task --cluster $CLUSTER --launch-type FARGATE --task-definition $TASK_DEFINITION --network-configuration "awsvpcConfiguration={subnets=[$PRIMARY_SUBNET],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" --region $REGION)
if [ $? -ne 0 ]; then
  echo "Error: Failed to run task"
  echo "RUN_TASK_OUTPUT: $RUN_TASK_OUTPUT"
  exit 1
fi

TASK_ARN=$(echo $RUN_TASK_OUTPUT | jq -r '.tasks[0].taskArn')
echo "Task ARN: $TASK_ARN"
