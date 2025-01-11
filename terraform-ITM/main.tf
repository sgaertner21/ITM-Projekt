terraform {
        required_providers {
                proxmox = {
                        source = "telmate/proxmox"
                        version = "3.0.1-rc4"
                }
        }
}

provider "proxmox" {

        pm_api_url= var.proxmox_api_url
        pm_api_token_id = var.proxmox_api_token_id
        pm_api_token_secret = var.proxmox_api_token_secret
        pm_tls_insecure = true
}

# Module einbinden
module "ansible" {
  source         = "./modules/ansible"
  vm_name        = var.ansible_vm_name
  vm_id          = var.ansible_vm_id
  proxmox_node   = var.ansible_vm_proxmox_node
  cores          = var.ansible_vm_cores
  memory         = var.ansible_vm_memory
  network_bridge = "vmbr0"
  ip             = var.ansible_vm_ip
  ssh_keys       = var.ansible_ssh_keys
}

module "OPNsense" {
  source         = "./modules/OPNsense"
  vm_name        = var.opnsense_vm_name
  vm_id          = var.opnsense_vm_id
  proxmox_node   = var.opnsense_vm_proxmox_node
  cores          = var.opnsense_vm_cores
  memory         = var.opnsense_vm_memory
  network_bridge = "vmbr0"
  ip             = var.opnsense_vm_ip
  ssh_keys       = var.opnsense_ssh_keys
}