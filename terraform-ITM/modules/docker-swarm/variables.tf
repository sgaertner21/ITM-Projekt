variable "docker_vms" {
    description = "Liste der Docker-VMs"
    type        = map(object({
        ip             = string
        gateway        = string
        proxmox_node   = string
        cores          = number
        memory         = number
        network_bridge = string
        ssh_keys       = list(string)
        tags           = list(string)
    }))
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

variable "smb_nextcloud_user" {
    description = "Benutzername für SMB-Share von Nextcloud"
    type        = string
}

variable "smb_nextcloud_password" {
    description = "Passwort für SMB-Share von Nextcloud"
    type        = string
}