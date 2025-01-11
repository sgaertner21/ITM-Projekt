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

resource "proxmox_virtual_environment_network_linux_bridge" "OPNsense_bridge" {
        node_name = var.proxmox_node
        name = "vmbr1"
        address = "10.0.0.2"
        comment = "Internal LAN network"
}

resource "proxmox_vm_qemu" "OPNsense_vm" {
        name = var.vm_name
        vmid = var.vm_id
        target_node = var.proxmox_node

        # Hardware-Spezifikationen
        full_clone = false
        clone = "ubuntu-server-noble"
        agent = 0
        memory = var.memory
        cores = var.cores
        scsihw = "virtio-scsi-pci"

        # Speicher VM
        disk {
                storage = "local"
                type = "disk"
                size = "20G"
                slot = "virtio0"
        }

        # Netzwerk
        network {
                model = "virtio"
                bridge = var.wan_bridge
        }
        network {
                model = "virtio"
                bridge = proxmox_virtual_environment_network_linux_bridge.OPNsense_bridge.name
        }
}