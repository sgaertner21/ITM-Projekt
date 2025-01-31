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
        provider = bpg-proxmox

        node_name = var.proxmox_node
        name = var.proxmox_ve_network_bridge_lan
        address = "${var.proxmox_lan_ip}/24"
        comment = "Internal LAN network"
}

resource "proxmox_cloud_init_disk" "OPNsense_cloud_init" {
        provider = telmate-proxmox

        name = "cloudinit"
        pve_node = var.proxmox_node
        storage = "local"
        meta_data = yamlencode({
                instance_id = sha1(var.vm_name)
                local_hostname = var.vm_name
        })
        user_data = templatefile("${path.module}/files/user_data.tftpl", {
                vm_network_interface_lan = var.vm_network_interface_lan
                vm_network_interface_wan = var.vm_network_interface_wan
                vm_lan_ip = var.vm_lan_ip
                vm_wan_ip = var.vm_wan_ip
                vm_dns_server = var.vm_dns_server
                vm_wan_subnet_cidr = "24"
                ssh_keys_base64 = base64encode(join("\r\n", var.ssh_keys))
        })
}

resource "proxmox_vm_qemu" "OPNsense_vm" {
        provider = telmate-proxmox

        name = var.vm_name
        vmid = var.vm_id
        target_node = var.proxmox_node

        # Hardware-Spezifikationen
        full_clone = true
        clone = "OPNsense-template"
        agent = 1
        memory = var.memory
        cores = var.cores
        scsihw = "lsi"
        onboot = "true"

        # Speicher VM
        disk {
                storage = "local"
                type = "disk"
                size = "20G"
                format = "qcow2"
                slot = "scsi0"
                emulatessd = true
        }

        # Clodinit Disk
        disk {
                storage = "local"
                type = "cdrom"
                iso = "${proxmox_cloud_init_disk.OPNsense_cloud_init.id}"
                format = "qcow2"
                slot = "ide0"
        }

        boot = "order=scsi0"

        # Netzwerk
        network {
                model = "e1000"
                bridge = var.proxmox_ve_network_bridge_wan
        }
        network {
                model = "e1000"
                bridge = proxmox_virtual_environment_network_linux_bridge.OPNsense_bridge.name
        }

        connection {
                host = var.vm_wan_ip
                user = "root"
                private_key = file("~/.ssh/id_rsa")
        }

        provisioner "remote-exec" {
                inline = [
                        "if [ ! -f /var/lib/cloud/instance/boot-finished ]; then echo 'Waiting for cloud-init...'; fi",
                        "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
                        "echo 'cloud-init finished!'"
                ]
        }
}

resource "terraform_data" "run_ansible" {
        depends_on = [ proxmox_vm_qemu.OPNsense_vm ]

        connection {
                host        =   var.ansible_ip
                user        =   "ansible"
                private_key =   file("~/.ssh/id_rsa")
        }

        provisioner "remote-exec" {
                inline = [
                        "cd ~/ansible",
                        "ansible-playbook -i inventory_proxmox.yml --extra-vars \"var_hosts_opnsense=${var.vm_name} var_ansible_public_ssh_key=${var.ansible_shh_key} var_ansible_opnsense_api_key=${random_id.opnsense_api_key.b64_std} var_ansible_opnsense_api_secret_hash=${local.opnsense_api_secret_hash}\" opnsense/playbook.yml"
                ]          
        }
}

resource "random_id" "opnsense_api_key" {
  byte_length = 60
}

resource "random_bytes" "opnsense_api_secret" {
  length = 60
}

locals {
  opnsense_api_secret_hash = "$6$$$$${sha512(random_bytes.opnsense_api_secret.base64)}"
}


