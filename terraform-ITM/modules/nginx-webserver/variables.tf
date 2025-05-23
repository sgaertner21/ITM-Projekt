variable "vm_name" {
  description = "Name der VM"
  type        = string
}

variable "vm_id" {
  description = "ID der VM"
  type        = number
  nullable    = true
}

variable "ip" {
  description = "DHCP oder IP-Adresse der VM"
  type        = string
  default     = "dhcp"
}

variable "gateway" {
  description = "Gateway-IP-Adresse der VM"
  type        = string
  nullable    = true
  default     = null
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

variable "opnsense_vm_name" {
    description = "Hostname der OPNsense-VM"
    type        = string
}

variable "opnsense_api_key" {
    description = "API-Key für OPNsense"
    type        = string
}

variable "opnsense_api_secret" {
    description = "API-Secret für OPNsense"
    type        = string
}

variable "external_port" {
    description = "Port, auf dem der Webserver von extern erreichbar ist"
    type        = number
}