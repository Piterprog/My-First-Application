#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 {cluster} {task-definition} {subnet-id} {security-group-id} {service-name}"
    exit 1
fi

# Assign input variables
cluster=$1
task_definition=$2
subnet_id=$3
security_group_id=$4
service_name=$5

# Create a new ECS service
echo "Creating service in Amazon ECS..."
aws ecs create-service --cluster "$cluster" --service-name "$service_name" --task-definition "$task_definition" --desired-count 1 --network-configuration "awsvpcConfiguration={subnets=[$subnet_id],securityGroups=[$security_group_id]}"

# Start the service
echo "Starting the service..."
aws ecs update-service --cluster "$cluster" --service "$service_name" --desired-count 1

# Get the latest task definition ARN by name
task_definition=$(aws ecs list-task-definitions --family-prefix "$task_definition" --sort DESC | jq -r '.taskDefinitionArns[0]')

# Run the task in the specified environment
echo "Running task in Amazon ECS..."
result=$(aws ecs run-task --task-definition "$task_definition" --launch-type FARGATE --cluster "$cluster" --network-configuration "awsvpcConfiguration={subnets=[$subnet_id],securityGroups=[$security_group_id]}")

# Extract the task ID
task_id=$(echo "$result" | jq -r '.tasks[0].taskArn' | cut -d '/' -f 2)

# Get the task status
echo "Getting task status..."
task_status=$(aws ecs describe-tasks --tasks "$task_id" --cluster "$cluster" | jq -r '.tasks[0].lastStatus')

# Form the link to the log group
log_group_link="https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups/log-group/"

# Display the task status and log group link
if [ "$task_status" == "RUNNING" ]; then
    echo "The task is currently running."
    echo "Log Group Link: $log_group_link"
elif [ "$task_status" == "STOPPED" ]; then
    echo "The task has stopped."
    echo "Log Group Link: $log_group_link"
else
    echo "Failed to start the task."
fi






