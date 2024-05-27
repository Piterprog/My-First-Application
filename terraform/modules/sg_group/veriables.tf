variable "vpc_id" {
  type = string
}
variable "ingress_from_port" {
  type = number
}
variable "ingress_to_port" {
  type = number
}
variable "ingress_protocol" {
 type = string
}
variable "ingress_cidr_blocks" {
  type = list(string)
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
