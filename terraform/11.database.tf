

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



output "rds_endpoint" {
  value = aws_db_instance.my_db_instance.endpoint
}

