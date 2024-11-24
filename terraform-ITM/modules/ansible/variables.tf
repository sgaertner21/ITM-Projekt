variable "vm_name" {
  description = "Name der VM"
  type        = string
}

variable "vm_id" {
  description = "ID der VM"
  type        = number
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

variable "nameserver" {
  description = "DNS Server der VM"
  type        = string
  default     = "9.9.9.9"
}

variable "ip" {
  description = "IP der VM"
  type        = string
}

variable "gateway" {
  description = "Gateway der VM"
  type        = string
  default     = "172.16.0.1"
}

variable "network_bridge" {
  description = "Netzwerkbrücke für die VM"
  type        = string
  default     = "vmbr0"
}
