#!/bin/bash

# Command line parameters
SERVICE_NAME=$1  # The name of the task or task family
ENVIRONMENT=$2  # The environment (e.g., production, staging)
CLUSTER=$3  # The name of the ECS cluster
SECURITY_GROUP=${4:-default}  # The security group ID (default based on environment)
SUBNET=${5:-default}  # The subnet ID (default based on environment)
VPC_ID=${6:-default}  # The VPC ID (default based on environment)

# Constant values
REGION="us-east-1"  # Specified AWS region
LOG_PREFIX="/ecs"

# Define default values based on environment
if [ "$ENVIRONMENT" == "production" ]; then
  DEFAULT_SECURITY_GROUP=""
  DEFAULT_SUBNET=""  # Specify the default subnet value for production
  DEFAULT_VPC_ID=""  # Specify the default VPC value for production
else
  DEFAULT_SECURITY_GROUP="sg-054071f2335d2c51e"
  DEFAULT_SUBNET="subnet-0aaf282e59bb73704"  # Specify the default subnet value for staging
  DEFAULT_VPC_ID="vpc-03dab4e3ca86969fb"  # Specify the default VPC value for staging
fi

# Override default values if not provided
SECURITY_GROUP=${SECURITY_GROUP:-$DEFAULT_SECURITY_GROUP}
SUBNET=${SUBNET:-$DEFAULT_SUBNET}
VPC_ID=${VPC_ID:-$DEFAULT_VPC_ID}

# Define the log group name
LOG_GROUP="$LOG_PREFIX/$SERVICE_NAME/$ENVIRONMENT"

# Check if the log group exists
LOG_GROUP_EXISTS=$(aws logs describe-log-groups --log-group-name-prefix $LOG_GROUP --region $REGION --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" --output text)

# Create the log group if it does not exist
if [ -z "$LOG_GROUP_EXISTS" ]; then
  aws logs create-log-group --log-group-name $LOG_GROUP --region $REGION
  echo "Log group created: $LOG_GROUP"
else
  echo "Log group already exists: $LOG_GROUP"
fi

# Fetching the latest revision of the task definition
TASK_DEFINITION=$(aws ecs list-task-definitions --family-prefix $SERVICE_NAME --sort DESC --query 'taskDefinitionArns[0]' --output text --region $REGION)

# Running the ECS task
RUN_TASK_OUTPUT=$(aws ecs run-task --cluster $CLUSTER --launch-type FARGATE --task-definition $TASK_DEFINITION --network-configuration "awsvpcConfiguration={subnets=[$SUBNET],securityGroups=[$SECURITY_GROUP],assignPublicIp=DISABLED}" --region $REGION)

# Extracting the Task ARN from the output
TASK_ARN=$(echo $RUN_TASK_OUTPUT | jq -r '.tasks[0].taskArn')

# Constructing the log group link
LOG_GROUP_LINK="https://console.aws.amazon.com/cloudwatch/home?region=$REGION#logsV2:log-groups/log-group/$LOG_GROUP"

# Outputting the Task ARN and log group link
echo "Task ARN: $TASK_ARN"
echo "Log Group Link: $LOG_GROUP_LINK"

