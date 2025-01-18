variable "bind9_ssh_keys" {
        description = "SSH-Public-Key für den Zugriff auf die VMs"
        type = list(string)
}

variable "bind9_vm_name" {
        description = "Name der VM"
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