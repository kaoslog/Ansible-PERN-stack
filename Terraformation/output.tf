output "control_node_public_ip" {
  description = "IP pubblico del Control Node a cui connettersi via SSH"
  value       = aws_instance.control_node.public_ip
}

output "scp_command_to_upload_key" {
  description = "Esegui questo comando dal tuo pc (nella cartella dove hai la tua chiave .pem) per caricarla sul control node"
  value       = "scp -i \"${var.key_name}.pem\" \"${var.key_name}.pem\" ec2-user@${aws_instance.control_node.public_ip}:/home/ec2-user/${var.key_name}.pem"
}