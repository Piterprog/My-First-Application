# aws cli command for create service

aws ecs create-service --cli-input-json file://web-app-service.json --cluster Ecs_cluster

# aws cli commnad for update service

aws ecs update-service --cluster Ecs_cluster --service web-app-service --task-definition web-app-hello-from-ecs-cluster:37
