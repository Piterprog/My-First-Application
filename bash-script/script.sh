#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 {cluster} {task-definition} {subnet-id} {security-group-id} {service-name} {vpc-id}"
    exit 1
fi

# Assign input variables
cluster=$1
task_definition=$2
subnet_id=$3
security_group_id=$4
service_name=$5
vpc_id=$6

# Create a new ECS service
echo "Creating service in Amazon ECS..."
aws ecs create-service --cluster "$cluster" --service-name "$service_name" --task-definition "$task_definition" --desired-count 1 --network-configuration "awsvpcConfiguration={subnets=[$subnet_id],securityGroups=[$security_group_id],assignPublicIp=ENABLED}" --vpc $vpc_id

# Получаем последнюю версию задачи по имени
task_definition=$(aws ecs list-task-definitions --family-prefix "$task_definition" --sort DESC | jq -r '.taskDefinitionArns[0]')

# Запускаем задачу в указанной среде
echo "Запуск задачи в Amazon ECS..."
result=$(aws ecs run-task --task-definition "$task_definition" --launch-type FARGATE --cluster "$cluster" --network-configuration "awsvpcConfiguration={subnets=[$subnet_id],securityGroups=[$security_group_id],assignPublicIp=ENABLED}" --vpc $vpc_id)

# Извлекаем идентификатор задачи
task_id=$(echo "$result" | jq -r '.tasks[0].taskArn' | cut -d '/' -f 2)

# Получаем статус задачи
echo "Получение статуса задачи..."
task_status=$(aws ecs describe-tasks --tasks "$task_id" --cluster "$cluster" | jq -r '.tasks[0].lastStatus')

# Формируем ссылку на группу журналов
log_group_link="https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups/log-group/"

# Отображаем статус задачи и ссылку на группу журналов
if [ "$task_status" == "RUNNING" ]; then
    echo "Задача в данный момент выполняется."
    echo "Ссылка на группу журналов: $log_group_link"
elif [ "$task_status" == "STOPPED" ]; then
    echo "Задача остановлена."
    echo "Ссылка на группу журналов: $log_group_link"
else
    echo "Не удалось запустить задачу."
fi




