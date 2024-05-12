#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 {name} {env} {cluster_name} {region}"
    exit 1
fi

# Assign input variables
name=$1
env=$2
cluster_name=$3
region=$4

# Get the corresponding task definition with the latest revision
task_definition=$(aws ecs list-task-definitions --family-prefix $name --sort DESC --region $region | jq -r '.taskDefinitionArns[0]')

# Run the task in the specified environment
result=$(aws ecs run-task --task-definition $task_definition --launch-type FARGATE --cluster $cluster_name --region $region)

# Extract the task ID
task_id=$(echo $result | jq -r '.tasks[0].taskArn' | cut -d '/' -f 2)

# Get the task status
task_status=$(aws ecs describe-tasks --tasks $task_id --cluster $cluster_name --region $region | jq -r '.tasks[0].lastStatus')

# Form the link to the log group
log_group_link="https://console.aws.amazon.com/cloudwatch/home?region=$region#logsV2:log-groups/log-group/"

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
