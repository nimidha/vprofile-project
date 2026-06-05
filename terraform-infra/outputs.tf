output "network_id" {
  value       = aws_vpc.vprofile_network.id
  description = "The unique tracking ID assigned to our generated VPC"
}

output "subnet_id" {
  value       = aws_subnet.vprofile_public_subnet.id
  description = "The unique tracking ID assigned to our subnet"
}
