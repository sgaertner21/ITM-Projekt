terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

resource "proxmox_vm_qemu" "nginx-webserver" {
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
    size    = "20G"
    slot    = "virtio0"
  }

  # Netzwerk
  network {
    model  = "virtio"
    bridge = var.network_bridge
  }
}

locals {
  ansible_variables = replace(jsonencode({
    var_hosts_webserver = var.vm_name
    var_hosts_opnsense = var.opnsense_vm_name
    var_opnsense_firewall = var.opnsense_vm_name
    var_opnsense_api_key = var.opnsense_api_key
    var_opnsense_api_secret = nonsensitive(var.opnsense_api_secret)
    var_webserver = var.vm_name
    var_external_port = tostring(var.external_port)
  }), "\"", "\\\"")
}

resource "terraform_data" "run_ansible" {
  depends_on = [proxmox_vm_qemu.nginx-webserver]

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
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" nginx-webserver/playbook.yml"
    ]
  }
}