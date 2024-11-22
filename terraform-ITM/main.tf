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
module "vm_example" {
  source         = "./modules/vm"
  vm_name        = "example-vm"
  vm_id          = 100
  proxmox_node   = "pve-node1"
  cores          = 2
  memory         = 2048
  network_bridge = "vmbr0"
}