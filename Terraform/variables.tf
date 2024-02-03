variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "env" {
  default = "dev"
}

variable "public_subnet_cidrs" {
  default = [
    "10.0.10.0/24",
    "10.0.20.0/24"
  ]
}

variable "private_subnet_cidrs" {
  default = [
    "10.0.11.0/24",
    "10.0.21.0/24"
  ]
}

variable "database_subnet_cidrs" {
  default = [
    "10.0.12.0/24",
    "10.0.22.0/24"
  ]
}

variable "Security_vpc_Musad" {
  description = "Security group for HTTPS , HTTP "
  default     = "0.0.0.0/0"
}

variable "Security_database" {
  description = "Security froup database port 3306"
  default = [
     "10.0.12.0/24",
     "10.0.22.0/24"
  ] 
}

variable "security_group_name" {
  description = "Name for security group"
  default     = "Database-group"
}