variable "vm_name" {
  description = "Name der VM"
  type        = string
}

variable "vm_id" {
  description = "ID der VM"
  type        = number
  nullable = true
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

variable "proxmox_ve_network_bridge_wan" {
  description = "Bridge für WAN"
  type        = string
  default     = "vmbr0"
}

variable "proxmox_ve_network_bridge_lan" {
    description = "Bridge für LAN"
    type    = string
    default = "vmbr1"
}

variable "vm_network_interface_wan" {
    type    = string
    default = "em0"
}

variable "vm_network_interface_lan" {
    type    = string
    default = "em1"
}

variable "vm_lan_ip" {
    type    = string  
}

variable "vm_wan_ip" {
    type    = string
}

variable "proxmox_lan_ip" {
    type    = string
}

variable "vm_dns_server" {
    type    = string
}

variable "ssh_keys" {
    description = "SSH-Keys für den User root"
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