



variable "db_username" {
  description = "Username for the database"
  type        = string
}

variable "db_password" {
  description = "Password for the database"
  type        = string
}

resource "aws_db_subnet_group" "my_db_subnet_group" {
  name       = "security_group_db"
  subnet_ids = ["subnet-09b818015684f552c", "subnet-0d092aaad9191bcb5"]  # Замените на фактические subnet_id в вашей VPC
}

resource "aws_db_instance" "my_db_instance" {
  identifier             = "my-db-instance"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.my_db_subnet_group.name
  vpc_security_group_ids = ["sg-023721f8e2af68130"]  # Замените на фактический ID вашей security group
  publicly_accessible    = false
}

output "rds_endpoint" {
  value = aws_db_instance.my_db_instance.endpoint
}

