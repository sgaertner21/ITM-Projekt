variable "opnsense_ssh_keys" {
        description = "SSH-Public-Key für den Zugriff auf die VMs"
        type = list(string)
}

variable "opnsense_vm_name" {
        description = "Name der VM"
        type = string
}

variable "opnsense_vm_cores" {
        description = "Anzahl der CPU-Kerne"
        type = number
        default = 1
}

variable "opnsense_vm_memory" {
        description = "Arbeitsspeicher (MB)"
        type = number
        default = 1024
}

variable "opnsense_vm_proxmox_node" {
        description = "Proxmox-Node, auf dem die VM läuft"
        type = string
}

variable "opnsense_vm_id" {
        description = "ID der VM"
        type = number
        nullable = true
}

variable "opnsense_vm_ip" {
        description = "IP-Adresse der VM"
        type = string  
}