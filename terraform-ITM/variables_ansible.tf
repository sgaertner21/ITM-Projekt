variable "ansible_vm_name" {
        description = "Name der VM"
        type = string
}

variable "ansible_vm_cores" {
        description = "Anzahl der CPU-Kerne"
        type = number
        default = 1
}

variable "ansible_vm_memory" {
        description = "Arbeitsspeicher (MB)"
        type = number
        default = 1024
}

variable "ansible_proxmox_node" {
        description = "Proxmox-Node, auf dem die VM läuft"
        type = string
}

variable "ansible_vm_id" {
        description = "ID der VM"
        type = number
        nullable = true
}

variable "ansible_vm_ip" {
        description = "IP-Adresse der VM"
        type = string  
}

variable "ansible_vm_subnet_cidr" {
        description = "Subnetzmaske der VM im CIDR-Format"
        type = number
        default = 24
}

variable "ansible_vm_gateway" {
        description = "Gateway der VM"
        type        = string
}

variable "ansible_vm_network_config_typ_lan" {
        description = "Typ der Netzwerkkonfiguration für LAN"
        type        = string
        default     = "dhcp"
}

variable "ansible_vm_ip_lan" {
        description = "IP-Adresse der VM im LAN"
        type        = string
        nullable    = true
        default     = null
}

variable "ansible_vm_subnet_cidr_lan" {
        description = "Subnetzmaske LAN der VM im CIDR-Format"
        type = number
        nullable = true
        default = 24
}

variable "ansible_vm_gateway_lan" {
        description = "Gateway-IP-Adresse im LAN der VM"
        type        = string
        nullable    = true
        default     = null
}

variable "ansible_ip_address_filter_for_connection" {
        description = "Regex für IP-Adressen, die Ansible benutzen darf um sich zu verbinden"
        type = string
}