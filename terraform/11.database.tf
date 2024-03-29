variable "db_username" {
  type = string
  description = "Username off my database"
}

variable "db_password" {
  type = string
  description = "Password off my database"
}

#------------------------------------------------- data source ---------------------------------------

data "terraform_remote_state" "vpc" {
  backend = "remote"
  config = {
    organization = "piterprog_prod"
    workspaces = {
      name = "My-First-Application"
    }
  }
}

#--------------------------------------------------  database ----------------------------------------

resource "aws_db_subnet_group" "mysql" {
  name       = "mysql"
  subnet_ids = ["subnet-047ce0155b86bac99", "subnet-00e4005620f99f16f"]

  tags = {
    Name = "My MySQL DB Subnet Group"
  }
}


resource "aws_db_instance" "mysql" {
  engine                 = "MySQL"
  identifier             = "myrdsinstance"
  allocated_storage      =  20
  engine_version         = "8.0.35"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0.35"
  vpc_security_group_ids = ["sg-05217f2d9186e931a"]
  skip_final_snapshot    = true
  publicly_accessible    =  false
  
}

output "db_instance_endpoint" {
  value       = aws_db_instance.mysql.endpoint
}


#----------------------------------- instance bastion for connetion database -------------------------

resource "aws_instance" "bastion" {
  ami                    = "ami-0c101f26f147fa7fd" 
  instance_type          = "t2.micro"
  subnet_id              = "subnet-046174e7c08fc2aac"
  key_name               = "SSH-connetion" 

  tags = {
    Name                 = "bastion_host"
  } 

}