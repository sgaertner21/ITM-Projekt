terraform {
        required_providers {
                proxmox = {
                        source = "telmate/proxmox"
                        version = "3.0.1-rc4"
                }
        }
}

resource "proxmox_vm_qemu" "OPNsense" {
    
}