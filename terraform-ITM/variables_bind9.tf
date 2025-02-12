variable "bind9_vm_name" {
  description = "Name der VM"
  type = string
}

variable "bind9_vm_ip" {
  description = "IP-Adresse der VM"
  type = string
}

variable "bind9_vm_subnet_cidr" {
  description = "Subnetzmaske der VM im CIDR Format"
  type = number
  default = 24
}

variable "bind9_vm_gateway" {
  description = "Gateway-IP-Adresse der VM"
  type = string
}

variable "bind9_vm_cores" {
  description = "Anzahl der CPU-Kerne"
  type = number
  default = 1
}

variable "bind9_vm_memory" {
  description = "Arbeitsspeicher (MB)"
  type = number
  default = 1024
}

variable "bind9_proxmox_node" {
  description = "Proxmox-Node, auf dem die VM läuft"
  type = string
}

variable "bind9_vm_id" {
  description = "ID der VM"
  type = number
  nullable = true
}