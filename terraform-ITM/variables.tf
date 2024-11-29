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