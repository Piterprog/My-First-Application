# ECS monitoring using Prometheus and Grafana

1.Create Task Definitions for cAdvisor, Node-Exporter, Prometheus and Grafana:

  aws ecs register-task-definition --cli-input-json file://./cadvisor-node-exporter-definition.json --region us-east-1       
 
  aws ecs register-task-definition --cli-input-json file://./prometheus-grafana-definition.json --region us-east-1

2.Create a DAEMON Service to run cAdvisor, Node-Exporter on every node in ECS Cluster:

  aws ecs create-service --cluster MyWorkingCluster --service-name cadvisor-node-exporter --task-definition cadvisor-node- 
     exporter-definition:1 --launch-type EC2 --scheduling-strategy DAEMON --region us-east-1

3.Run one ECS Task for Prometheus and Grafana in the clsuter:

  aws ecs run-task --cluster MyWorkingCluster --task-definition prometheus-grafana-definition:1  --region us-east-1

4.Access Grafana Dashboard using URL: http://monitor_ec2_public_ip:3000 Use user:admin and password:admin to login and then 
  reset the password.


5.After logginig in, add datasource:

 
6.Useful Grafana Dashboards:

 Docker Host Monitoring: 11074, 10619, 395
 Docker Monitoring: 193
 Docker monitoring with Node selection: 8321
