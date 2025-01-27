terraform {
        required_providers {
                proxmox = {
                        source = "telmate/proxmox"
                        version = "3.0.1-rc4"
                }
        }
}

resource "proxmox_cloud_init_disk" "ansible_cloud_init" {
  name = var.vm_name
  pve_node = var.proxmox_node
  storage = "local"

  meta_data = jsonencode({
    instance-id = sha1(var.vm_name)
  })

  user_data = <<-EOT
  #cloud-config
  users: 
    - name: ansible
      ssh-authorized-keys: ${var.ssh_keys}
      sudo: ['ALL=(ALL) NOPASSWD:ALL']
      groups: sudo
      shell: /bin/bash
  runcmd:
    - sudo apt update
    - sudo apt install software-properties-common
    - sudo add-apt-repository --yes --update ppa:ansible/ansible
    - sudo apt install ansible -y
  ssh_keys:
    rsa_private: ${tls_private_key.ansible.private_key_pem}
    rsa_public: ${tls_private_key.ansible.public_key_openssh}
  EOT
}

resource "proxmox_vm_qemu" "ansible" {
  name = var.vm_name
  vmid = var.vm_id
  target_node = var.proxmox_node

  # Hardware-Spezifikationen
  full_clone = false
  clone = "ubuntu-server-noble"
  agent = 1
  memory = var.memory
  cores = var.cores
  scsihw = "virtio-scsi-pci"
  os_type = "ubuntu"
  nameserver = var.nameserver
  ipconfig0 = "ip=${var.ip},gw=${var.gateway}"

  # Cloud-Init disk
  disk {
    storage = "local"
    type = "cdrom"
    iso = "${proxmox_cloud_init_disk.ansible_cloud_init.id}"
    format = "qcow2"
    slot = "ide0"
  }

  # Speicher VM
  disk {
    storage = "local"
    type = "disk"
    size = "20G"
    slot = "virtio0"
  }

  # WAN
  network {
    model = "virtio"
    bridge = "vmbr0"
  }

  # LAN
  network {
    model = "virtio"
    bridge = "vmbr1"
  }

  connection {
    host = var.ip
    user = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  # Ansible Inventory
  provisioner "file" {
    source = "${path}/ansible/"
    destination = "/root/ansible/"
  }

  provisioner "file" {
    content = templatefile("${module.path}/files/proxmox_inventory.tftpl", {
      proxmox_url = var.proxmox_url
      proxmox_user = proxmox_virtual_environment_user.ansible_user.user_id
      proxmox_token_id = proxmox_virtual_environment_user_token.ansible_api.token_name
      proxmox_token_secret = proxmox_virtual_environment_user_token.ansible_api.value
      ip_regex = var.ip_regex
    }) 
    destination = "~/ansible/inventory_proxmox.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "ansible-playbook -i ~/ansible/inventory_proxmox.yml ~/ansible/ansible-host/playbook.yml",
    ]
  }
}

# Erzeugen eines SSH-Keys für Ansible
resource "tls_private_key" "ansible" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "proxmox_virtual_environment_user" "ansible_user" {
    user_id = "ansible@pve"
    comment = "User for Ansible dynamic inventory"
}

resource "proxmox_virtual_environment_user_token" "ansible_api" {
    token_name = "ansible"
    user_id = proxmox_virtual_environment_user.ansible_user.id
    privileges_separation = true
}

resource "proxmox_virtual_environment_acl" "ansible_api_acl" {
    path = "/"
    role_id = "Administrator"
    propagate = true
    token_id = proxmox_virtual_environment_user_token.ansible_api.id
}