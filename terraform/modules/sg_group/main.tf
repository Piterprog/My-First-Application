resource "aws_security_group" "this" {
  name        = var.sg_name
  description = var.sg_desctiption
  vpc_id      = var.vpc 

 dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port   = ingress_value.from_port
    to_port     = ingress_value.to_port
    protocol    = ingress_value.protocol
    cidr_blocks = ingress_value.cidr_blocks  
  }
}
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.tag
  }
}
