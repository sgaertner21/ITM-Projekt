output "public_ssh_key" {
  description = "Public-SSH-Key der virtuellen Maschine"
  value       = tls_private_key.ansible.public_key_openssh
}

output "private_ssh_key" {
  description = "Private-SSH-Key der virtuellen Maschine"
  value       = tls_private_key.ansible.private_key_openssh
}