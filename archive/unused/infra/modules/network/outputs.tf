output "vpc_id" {
  description = "VPC id"
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "Public subnet id"
  value       = aws_subnet.public.id
}

output "route_table_id" {
  description = "Route table id"
  value       = aws_route_table.public.id
}
