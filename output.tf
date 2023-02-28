

# Declare the data source
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs  = data.aws_availability_zones.available.names
}



output "azs" {
    value = data.aws_availability_zones.available.names[0]
}
