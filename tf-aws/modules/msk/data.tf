# Fetch Available AZs
data "aws_availability_zones" "available" {
  state = "available"
}