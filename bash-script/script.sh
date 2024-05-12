#!/bin/bash

# Проверяем, правильное ли количество аргументов передано
if [ "$#" -ne 2 ]; then
    echo "Использование: $0 {name} {env}"
    exit 1
fi

# Присваиваем входные данные переменным
name=$1
env=$2
cluster_name=$3
region=$4

# Получаем соответствующее определение задачи с последней ревизией
task_definition=$(aws ecs list-task-definitions --family-prefix $name --sort DESC | jq -r '.taskDefinitionArns[0]')

# Запускаем задачу в указанной среде
result=$(aws ecs run-task --task-definition $task_definition --launch-type FARGATE --cluster $env)

# Извлекаем идентификатор задачи
task_id=$(echo $result | jq -r '.tasks[0].taskArn' | cut -d '/' -f 2)

# Получаем статус задачи
task_status=$(aws ecs describe-tasks --tasks $task_id --cluster $env | jq -r '.tasks[0].lastStatus')

# Формируем ссылку на группу журналов
log_group_link="https://console.aws.amazon.com/cloudwatch/home?region=<your-region>#logsV2:log-groups/log-group/"

# Выводим статус задачи и ссылку на группу журналов
if [ "$task_status" == "RUNNING" ]; then
    echo "Задача в данный момент выполняется."
    echo "Ссылка на группу журналов: $log_group_link"
elif [ "$task_status" == "STOPPED" ]; then
    echo "Задача остановлена."
    echo "Ссылка на группу журналов: $log_group_link"
else
    echo "Не удалось запустить задачу."
fi
