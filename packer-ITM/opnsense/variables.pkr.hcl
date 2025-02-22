# Variable Definitions for Packer configuration with Proxmox and VM network settings.

# URL of the Proxmox API endpoint. This variable specifies the base URL to access Proxmox.
variable "proxmox_api_url" {
    type = string
}

# Identifier for the Proxmox API token. This is used along with the token secret for authentication.
variable "proxmox_api_token_id" {
    type = string
}

# Secret associated with the Proxmox API token. This variable is marked sensitive to avoid exposure in logs.
variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

# Name of the Proxmox node on which the virtual machine will be deployed.
variable "proxmox_node" {
    type = string
}

# Unique identifier for the virtual machine in Proxmox.
# Using a number ensures the VM ID is strictly numeric.
variable "proxmox_vm_id" {
    type = number
}

# IP address assigned to the virtual machine.
variable "vm_ip" {
    type = string
}

# Gateway for the virtual machine's network.
variable "vm_gateway" {
    type = string
}

# Subnet configuration for the virtual machine's network.
variable "vm_subnet" {
    type = string
}

# DNS server address for configuring the virtual machine's network interfaces.
variable "vm_dns" {
    type = string
}