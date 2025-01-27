variable "opnsense_vm_name" {
  description = "Name der VM"
  type        = string
}

variable "opnsense_vm_id" {
  description = "ID der VM"
  type        = number
  nullable = true
}

variable "opnsense_proxmox_node" {
  description = "Proxmox-Node, auf dem die VM läuft"
  type        = string
}

variable "opnsense_cores" {
  description = "Anzahl der CPU-Kerne"
  type        = number
  default     = 1
}

variable "opnsense_memory" {
  description = "Arbeitsspeicher (MB)"
  type        = number
  default     = 1024
}

variable "opnsense_proxmox_ve_network_bridge_wan" {
  description = "Bridge für WAN"
  type        = string
  default     = "vmbr0"
}

variable "opnsense_proxmox_ve_network_bridge_lan" {
    description = "Bridge für LAN"
    type    = string
    default = "vmbr1"
}

variable "opnsense_vm_network_interface_wan" {
    type    = string
    default = "em0"
}

variable "opnsense_vm_network_interface_lan" {
    type    = string
    default = "em1"
}

variable "opnsense_vm_lan_ip" {
    type    = string  
}

variable "opnsense_vm_wan_ip" {
    type    = string
}

variable "proxmox_lan_ip" {
    type    = string
}

variable "opnsense_vm_dns_server" {
    type    = string
}

variable "opnsense_additional_ssh_keys" {
    description = "Zusätzliche SSH-Keys"
    type        = list(string)
    default     = []
}