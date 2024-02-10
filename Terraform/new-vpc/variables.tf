
variable "environment" {
  type    = string
  default = "development"  
}

variable "availability_zones" {
  description = "Список доступных зон доступности (Availability Zones)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}