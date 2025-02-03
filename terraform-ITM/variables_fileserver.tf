variable "fileserver_vm_name" {
        description = "Name der VM"
        type = string
}

variable "fileserver_vm_ip" {
        description = "DHCP oder IP-Adresse der VM"
        type        = string
        default     = "dhcp"
}

variable "fileserver_vm_gateway" {
        description = "Gateway-IP-Adresse der VM"
        type        = string
        nullable    = true
        default     = null
}

variable "fileserver_vm_cores" {
        description = "Anzahl der CPU-Kerne"
        type = number
        default = 1
}

variable "fileserver_vm_memory" {
        description = "Arbeitsspeicher (MB)"
        type = number
        default = 1024
}

variable "fileserver_proxmox_node" {
        description = "Proxmox-Node, auf dem die VM läuft"
        type = string
}

variable "fileserver_vm_id" {
        description = "ID der VM"
        type = number
        nullable = true
}