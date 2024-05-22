
resource "aws_vpc" "module" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name  = "module"
  }
}
