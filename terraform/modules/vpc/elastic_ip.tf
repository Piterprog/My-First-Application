
resource "aws_eip" "nat" {
    count    = length(var.private_subnet_cidrs)
    domain   = "vpc"
    tags     = {
        Name ="${var.env}-nat-gw-${count.index + 1}"
    }
}
