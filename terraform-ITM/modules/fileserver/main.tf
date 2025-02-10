terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

resource "proxmox_vm_qemu" "fileserver" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.proxmox_node

  # Hardware-Spezifikationen
  full_clone  = false
  clone       = "ubuntu-server-noble"
  agent       = 1
  memory      = var.memory
  cores       = var.cores
  scsihw      = "virtio-scsi-pci"
  os_type     = "cloud-init"
  ciuser      = "ansible"
  sshkeys     = join("\n", var.ssh_keys)
  ipconfig0   = var.ip == "dhcp" ? "ip=dhcp" : "ip=${var.ip},gw=${var.gateway}"

  # Speicher Cloud-Init
  disk {
    type    = "cloudinit"
    storage = "local"
    size    = "4M"
    slot    = "ide0"
  }

  # Speicher VM
  disk {
    storage = "local"
    type    = "disk"
    size    = "80G"
    slot    = "virtio0"
  }

  disk {
    storage = "local"
    type    = "disk"
    size    = "300G"
    slot    = "virtio1"
  }

  # Netzwerk
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
}

resource "random_password" "nextcloud_smb_password" {
  length  = 32
  special = false
}

locals {
  smb_nextcloud_user = "nextcloud-user"
  ansible_variables = replace(jsonencode({
    var_hosts_fileserver = var.vm_name,
    var_samba_groups = [
      {
        name = "nextcloud-group"
      }
    ],
    var_samba_users = [
      {
        name     = local.smb_nextcloud_user
        password = nonsensitive(random_password.nextcloud_smb_password.result)
        group    = "nextcloud-group"
      }
    ],
    var_nextcloud_data_owner_group = "nextcloud-group",
    var_nextcloud_data_valid_users = "@nextcloud-group",
    var_nextcloud_data_write_list = "@nextcloud-group",
    var_nextcloud_config_owner_group = "nextcloud-group",
    var_nextcloud_config_valid_users = "@nextcloud-group",
    var_nextcloud_config_write_list = "@nextcloud-group",
  }), "\"", "\\\"")
}

resource "terraform_data" "run_ansible" {
  depends_on = [proxmox_vm_qemu.fileserver]

  connection {
    host        = var.ansible_ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "cd ~/ansible",
      "command=\"ansible-inventory -i inventory_proxmox.yml --host ${var.vm_name} --yaml | grep ansible_host\"",
      "while ! eval $command; do echo \"Waiting for ansible inventory to build up...\"; sleep 5; done",
      "echo \"Host ${var.vm_name} found in ansible inventory!\"",
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" fileserver/playbook.yml"
    ]
  }
}