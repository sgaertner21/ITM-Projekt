terraform {
        required_providers {
                telmate-proxmox = {
                        source = "telmate/proxmox"
                        version = "3.0.1-rc4"
                }
                bpg-proxmox = {
                        source = "bpg/proxmox"
                        version = "0.69.0"
                }
        }
}

provider "telmate-proxmox" {

        pm_api_url= "${var.proxmox_url}/api2/json"
        pm_api_token_id = var.proxmox_api_token_id
        pm_api_token_secret = var.proxmox_api_token_secret
        pm_tls_insecure = true
}

provider "bpg-proxmox" {
        endpoint = "${var.proxmox_url}/api2/json"
        api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
        insecure  = true
}

# Module einbinden
module "ansible" {
        source          = "./modules/ansible"
        vm_name         = var.ansible_vm_name
        vm_id           = var.ansible_vm_id
        proxmox_node    = var.ansible_proxmox_node
        cores           = var.ansible_vm_cores
        memory          = var.ansible_vm_memory
        network_bridge  = "vmbr0"
        ip              = var.ansible_vm_ip
        ssh_keys        = concat([file("~/.ssh/id_rsa.pub")], var.ssh_keys)
        ip_regex        = var.ansible_ip_address_filter_for_connection
        proxmox_url     = var.proxmox_url
}

module "OPNsense" {
        source          = "./modules/OPNsense"
        vm_name         = var.opnsense_vm_name
        vm_id           = var.opnsense_vm_id
        proxmox_node    = var.opnsense_proxmox_node
        cores           = var.opnsense_cores
        memory          = var.opnsense_memory
        proxmox_ve_network_bridge_wan = var.opnsense_proxmox_ve_network_bridge_wan
        proxmox_ve_network_bridge_lan = var.opnsense_proxmox_ve_network_bridge_lan
        vm_network_interface_wan = var.opnsense_vm_network_interface_wan
        vm_network_interface_lan = var.opnsense_vm_network_interface_lan
        vm_lan_ip       = var.opnsense_vm_lan_ip
        vm_wan_ip       = var.opnsense_vm_wan_ip
        proxmox_lan_ip  = var.proxmox_lan_ip
        vm_dns_server   = var.opnsense_vm_dns_server
        ssh_keys        = concat([module.ansible.public_ssh_key], var.opnsense_additional_ssh_keys)
}

module "bind9" {
        source          = "./modules/bind9"
        vm_name         = var.bind9_vm_name
        vm_id           = var.bind9_vm_id
        proxmox_node    = var.bind9_proxmox_node
        cores           = var.bind9_vm_cores
        memory          = var.bind9_vm_memory
        network_bridge  = "vmbr1"
        ssh_keys        = concat([module.ansible.public_ssh_key], var.ssh_keys)
        ip              = var.bind9_vm_ip
        gateway         = var.bind9_vm_gateway

        depends_on = [module.OPNsense]
}