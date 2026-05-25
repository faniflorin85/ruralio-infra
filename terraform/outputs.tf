###############################################################################
# outputs.tf — Valori afișate după `terraform apply`
###############################################################################

output "instance_public_ip" {
  description = "IP-ul public (Elastic IP) al instanței — pune-l în DNS-ul ruralio.ro"
  value       = aws_eip.web.public_ip
}

output "instance_id" {
  description = "ID-ul instanței EC2"
  value       = aws_instance.web.id
}

output "ssh_command" {
  description = "Comandă gata de copiat pentru conectarea SSH"
  value       = "ssh -i ~/.ssh/ruralio ubuntu@${aws_eip.web.public_ip}"
}

output "vpc_id" {
  description = "ID-ul VPC-ului"
  value       = aws_vpc.main.id
}

output "github_actions_role_arn" {
  description = "ARN-ul rolului IAM — pune-l în workflow-ul GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}
