variable "vm_name" {
  description = "Name der VM"
  type        = string
}

variable "vm_id" {
  description = "ID der VM"
  type        = number
  nullable = true
}

variable "ip" {
  description = "IP-Adresse der VM"
  type        = string
}

variable "gateway" {
  description = "Gateway-IP-Adresse der VM"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox-Node, auf dem die VM läuft"
  type        = string
}

variable "cores" {
  description = "Anzahl der CPU-Kerne"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Arbeitsspeicher (MB)"
  type        = number
  default     = 1024
}

variable "network_bridge" {
  description = "Netzwerkbrücke für die VM"
  type        = string
  default     = "vmbr1"
}

variable "ssh_keys" {
  description = "SSH-Keys für den User ansible"
  type        = list(string)
}

variable "ansible_ip" {
    description = "IP-Adresse des Ansible-Servers"
    type        = string
}

variable "ansible_ssh_key" {
    description = "SSH-Key für ansible"
    type        = string
}

variable "opnsense_ip" {
    description = "LAN IP-Adresse des OPNsense-Servers"
    type        = string
}

variable "opnsense_vm_name" {
    description = "Hostname der OPNsense-VM"
    type        = string
}