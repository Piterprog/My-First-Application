# aws cli command for create service

aws ecs create-service --cli-input-json file://./web-app-service.json --region us-east-1


# aws cli command for update service

aws ecs update-service --cluster Ecs_cluster --service web-service --task-definition web-app-hello-from-ecs-cluster:1 --force-new-deployment --region us-east-1


