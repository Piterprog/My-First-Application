data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "piterprog_prod"
    workspaces = {
      name = "My-First-Application"
    }
  }
}

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
  subnet_ids = data.terraform_remote_state.vpc.outputs.database_subnet_ids  
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
  vpc_security_group_ids = [data.terraform_remote_state.vpc.outputs.security_group_id]  
  publicly_accessible    = false
  deletion_protection    = false
}


output "rds_endpoint" {
  value = aws_db_instance.my_db_instance.endpoint
}

#------------------------------------------ instance for connet to database ---------------------------------

resource "aws_instance" "database_instance" {
    ami                    = "ami-0c101f26f147fa7fd"
    instance_type          = "t2.micro"
    subnet_id              = "subnet-03d1054297ed8f151"
    key_name               = "SSH-connetion"
    vpc_security_group_ids = ["sg-0bdd7631e9c68c669"]
    
    tags = {
      Name = "instance connet to database"
    }
    
    depends_on = [aws_db_instance.my_db_instance]
}