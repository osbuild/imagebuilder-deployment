output "vpc_id" {
  value = aws_vpc.main.id
}

output "manager_ip" {
  value = aws_eip.manager.public_ip
}