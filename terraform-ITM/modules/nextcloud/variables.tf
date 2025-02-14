variable "fileserver_vm_name" {
  description = "Name der Fileserver-VM"
  type = string
}

variable "smb_nextcloud_user" {
  description = "Benutzername für SMB-Share"
  type = string
}

variable "smb_nextcloud_password" {
  description = "Passwort für SMB-Share"
  type = string
}

variable "ansible_ip" {
  description = "IP-Adresse des Ansible-Hosts"
  type = string
}
