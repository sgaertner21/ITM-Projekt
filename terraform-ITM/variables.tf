variable "proxmox_api_url" {
        description = "URL des Proxmox API-Endpunkts"
        type = string
}

variable "proxmox_api_token_id" {
        description = "Token-ID für die Proxmox-API"
        type = string
        sensitive = true
}

variable "proxmox_api_token_secret" {
        description = "Token-Secret für die Proxmox-API"
        type =  string
        sensitive = true
}

variable "ssh_keys" {
        description = "SSH-Public-Key für den Zugriff auf die VMs"
        type = list(string)
}

variable "vm_name" {
        description = "Name der VM"
        type = string
}

variable "vm_cores" {
        description = "Anzahl der CPU-Kerne"
        type = number
        default = 1
}

variable "vm_memory" {
        description = "Arbeitsspeicher (MB)"
        type = number
        default = 1024
}

variable "vm_proxmox_node" {
        description = "Proxmox-Node, auf dem die VM läuft"
        type = string
}

variable "vm_id" {
        description = "ID der VM"
        type = number
        nullable = true
}

variable "vm_ip" {
        description = "IP-Adresse der VM"
        type = string  
}