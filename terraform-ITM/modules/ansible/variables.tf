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

variable "nameserver" {
  description = "DNS Server der VM"
  type        = string
  default     = "9.9.9.9"
}

variable "ip" {
  description = "IP der VM"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnetz der VM im CIDR-Format"
  type        = number
  default     = 24
  validation {
    condition = var.subnet_cidr >= 1 && var.subnet_cidr <= 30
    error_message = "Subnetz muss zwischen /1 und /30 liegen"
  }
}

variable "gateway" {
  description = "Gateway der VM"
  type        = string
}

variable "network_config_typ_lan" {
  description = "Typ der Netzwerkkonfiguration für LAN"
  type        = string
  default     = "dhcp"
}

variable "ip_lan" {
  description = "IP-Adresse der VM im LAN"
  type        = string
  nullable    = true
  default     = null
}

variable "subnet_cidr_lan" {
  description = "Subnetzmaske LAN der VM im CIDR-Format"
  type = number
  nullable = true
  default = 24
}

variable "gateway_lan" {
  description = "Gateway-IP-Adresse im LAN der VM"
  type        = string
  nullable    = true
  default     = null
}

variable "ssh_keys" {
  description = "SSH-Keys für den User ansible"
  type        = list(string)
}

variable "proxmox_url" {
  description = "URL des Proxmox-Servers"
  type        = string
}

variable "ip_regex" {
  description = "Regulärer Ausdruck für die IP-Adresse"
  type        = string
}