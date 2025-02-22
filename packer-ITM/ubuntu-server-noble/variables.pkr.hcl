# Variable Definitions

# The URL for the Proxmox API endpoint.
variable "proxmox_api_url" {
    type = string
}

# Identifier for the Proxmox API token.
variable "proxmox_api_token_id" {
    type = string
}

# Secret part of the Proxmox API token.
# Marked as sensitive for security; it won't be displayed in logs.
variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# The node name in the Proxmox cluster.
variable "proxmox_node" {
    type = string
}

# Unique identifier for the virtual machine (VM).
# This helps in managing and identifying VMs in Proxmox.
variable "proxmox_vm_id" {
    type = number
}

# IP address assigned to the VM.
variable "vm_ip" {
    type = string
}

# Network gateway for the VM.
variable "vm_gateway" {
    type = string
}

# Subnet mask or CIDR notation for the VM's network.
variable "vm_subnet" {
    type = string
}

# DNS server assigned for the VM.
variable "vm_dns" {
    type = string
}