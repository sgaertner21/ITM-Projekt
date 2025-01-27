output "ip" {
  description = "IP-Adresse der virtuellen Maschine"
  value       = proxmox_vm_qemu.ansible.ipconfig0
}

output "public_ssh_key" {
  description = "Public-SSH-Key der virtuellen Maschine"
  value       = tls_private_key.ansible.public_key_openssh
}

output "private_ssh_key" {
  description = "Private-SSH-Key der virtuellen Maschine"
  value       = tls_private_key.ansible.privat_key_openssh
}