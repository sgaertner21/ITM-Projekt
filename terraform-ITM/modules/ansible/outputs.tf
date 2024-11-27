output "ip" {
  description = "IP-Adresse der virtuellen Maschine"
  value       = proxmox_vm_qemu.ansible.ipconfig0
}