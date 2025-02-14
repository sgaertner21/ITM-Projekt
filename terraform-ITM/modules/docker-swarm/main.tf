terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

resource "proxmox_vm_qemu" "docker-swarm" {
  for_each    = var.docker_vms

  name        = each.key
  target_node = each.value.proxmox_node

  # Hardware-Spezifikationen
  full_clone  = false
  clone       = "ubuntu-server-noble"
  agent       = 1
  memory      = each.value.memory
  cores       = each.value.cores
  scsihw      = "virtio-scsi-pci"
  os_type     = "cloud-init"
  ciuser      = "ansible"
  sshkeys     = join("\n", each.value.ssh_keys)
  ipconfig0   = each.value.ip == "dhcp" ? "ip=dhcp" : "ip=${each.value.ip},gw=${each.value.gateway}"
  tags        = join(",", each.value.tags)

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
    bridge = each.value.network_bridge
  }
}

  # "var_hosts_webserver=${var.vm_name}",
  # "var_hosts_opnsense=${var.opnsense_vm_name}",
  # "var_opnsense_firewall=${var.opnsense_vm_name}",
  # "var_opnsense_api_key=${var.opnsense_api_key}",
  # "var_opnsense_api_secret=${nonsensitive(var.opnsense_api_secret)}",
  # "var_webserver=${var.vm_name}",
  # "var_external_port=${var.external_port}",

resource "terraform_data" "run_ansible" {
  depends_on = [proxmox_vm_qemu.docker-swarm]

  connection {
    host        = var.ansible_ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = concat(
      ["cd ~/ansible"],
      flatten([for vm_name in keys(var.docker_vms) : [
        "command=\"ansible-inventory -i inventory_proxmox.yml --host ${proxmox_vm_qemu.docker-swarm[vm_name].name} --yaml | grep ansible_host\"",
        "while ! eval $command; do echo \"Waiting for ansible inventory to build up...\"; sleep 5; done",
        "echo \"Host ${proxmox_vm_qemu.docker-swarm[vm_name].name} found in ansible inventory!\""
      ]]),
      ["ansible-playbook -i inventory_proxmox.yml --ssh-extra-args=\"-o StrictHostKeyChecking=no\" docker-swarm/playbook.yml"]
    )
  }
}

