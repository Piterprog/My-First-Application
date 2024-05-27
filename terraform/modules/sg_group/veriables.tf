variable "vpc_id" {
  type = string
}
variable "tags" {
  type = map(string)
  default = {}
}
variable "sg_name" {
  type = string
}
variable "sg_description" {
  type = string
}

variable "ingress_rules" {
 description = "LIst of ingress rules for the security group"
 type = list(object({
  from_port = number
  to_port   = number
  protocol  = string
  cidr_blocks = list(string) 
 }))
}


