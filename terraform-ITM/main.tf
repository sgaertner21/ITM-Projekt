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
  vm_name        = var.vm_name
  vm_id          = var.vm_id
  proxmox_node   = var.vm_proxmox_node
  cores          = var.vm_cores
  memory         = var.vm_memory
  network_bridge = "vmbr0"
  ip             = var.vm_ip
  ssh_keys       = var.ssh_keys
}

module "OPNsense" {
  source         = "./modules/OPNsense"
  vm_name        = var.vm_name
  vm_id          = var.vm_id
  proxmox_node   = var.vm_proxmox_node
  cores          = var.vm_cores
  memory         = var.vm_memory
  network_bridge = "vmbr0"
  ip             = var.vm_ip
  ssh_keys       = var.ssh_keys
}