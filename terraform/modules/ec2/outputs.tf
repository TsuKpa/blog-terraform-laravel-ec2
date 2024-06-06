
output "public_ip_ec2" {
  value = "You can ssh using this command: ssh -i ${var.key_name}.pem ubuntu@${aws_instance.web_server.public_ip}"
}
