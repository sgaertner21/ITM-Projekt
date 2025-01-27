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

variable "ansible_ip_address_filter_for_connection" {
        description = "Regex für IP-Adressen, die Ansible benutzen darf um sich zu verbinden"
        type = string
}