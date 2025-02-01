terraform {
        required_providers {
                proxmox = {
                        source = "telmate/proxmox"
                        version = "3.0.1-rc4"
                }
                tls = {
                        source = "hashicorp/tls"
                        version = "4.0.6"
                }
                bpg-proxmox = {
                        source = "bpg/proxmox"
                        version = "0.69.0"
                }
                macaddress = {
                        source = "ivoronin/macaddress"
                        version = "0.3.2"
                }
        }
}

resource "macaddress" "wan_address" {
}

resource "proxmox_cloud_init_disk" "ansible_cloud_init" {
  name     = var.vm_name
  pve_node = var.proxmox_node
  storage  = "local"

  meta_data = yamlencode({
    instance-id = sha1(var.vm_name)
  })

  network_config = yamlencode({
    version = 1
    config = [{
      type = "physical"
      name = "eth0"
      mac_address: "${macaddress.wan_address.address}"
      subnets = [{
        type = "static"
        address = "${var.ip}/${var.subnet_cidr}"
        gateway = "${var.gateway}"
      }]
      
    },
    {
      type = "nameserver"
      address = [
        "${var.nameserver}"
      ]
    }]
  })

  user_data = <<-EOT
  #cloud-config
  hostname: ${var.vm_name}
  manage_etc_hosts: false
  fqdn: ${var.vm_name}
  user: ansible
  ssh_authorized_keys: [${join(",", var.ssh_keys)}]
  users:
    - default
  chpasswd:
    expire: false
  runcmd:
    - sudo apt update
    - sudo apt install software-properties-common -y
    - sudo add-apt-repository --yes --update ppa:ansible/ansible
    - sudo apt install ansible -y
  ssh_keys:
    rsa_private: |
      ${indent(4, tls_private_key.ansible.private_key_pem)}
    rsa_public: |
      ${indent(4, tls_private_key.ansible.public_key_openssh)}
  EOT
}

resource "proxmox_vm_qemu" "ansible" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.proxmox_node

  # Hardware-Spezifikationen
  full_clone = false
  clone      = "ubuntu-server-noble"
  agent      = 1
  memory     = var.memory
  cores      = var.cores
  scsihw     = "virtio-scsi-pci"
  os_type    = "ubuntu"

  # Cloud-Init disk
  disk {
    storage = "local"
    type    = "cdrom"
    iso     = proxmox_cloud_init_disk.ansible_cloud_init.id
    format  = "qcow2"
    slot    = "ide0"
  }

  # Speicher VM
  disk {
    storage = "local"
    type    = "disk"
    size    = "20G"
    slot    = "virtio0"
  }

  # WAN
  network {
    model  = "virtio"
    bridge = "vmbr0"
    macaddr = macaddress.wan_address.address
  }

  # LAN
  network {
    model  = "virtio"
    bridge = "vmbr1"
  }

  connection {
    host        = var.ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "if [ ! -f /var/lib/cloud/instance/boot-finished ]; then echo 'Waiting for cloud-init...'; fi",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "echo 'cloud-init finished!'",
      "mkdir ~/ansible"
    ]
  }

  # Ansible Inventory
  provisioner "file" {
    source = "${path.root}/ansible/"
    destination = "ansible"
  }

  provisioner "file" {
    content = templatefile("${path.module}/files/proxmox_inventory.tftpl", {
      proxmox_url = var.proxmox_url
      proxmox_user = proxmox_virtual_environment_user.ansible_user.user_id
      proxmox_token_id = proxmox_virtual_environment_user_token.ansible_api.token_name
      proxmox_token_secret = regex(".*@.*!.*=(.*)", proxmox_virtual_environment_user_token.ansible_api.value)[0]
      ip_regex = var.ip_regex
    }) 
    destination = "ansible/inventory_proxmox.yml"
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
  rsa_bits  = 4096
}

resource "proxmox_virtual_environment_user" "ansible_user" {
  provider = bpg-proxmox

  user_id = "ansible@pve"
  comment = "User for Ansible dynamic inventory"
}

resource "proxmox_virtual_environment_user_token" "ansible_api" {
  provider = bpg-proxmox

  token_name            = "ansible"
  user_id               = proxmox_virtual_environment_user.ansible_user.id
  privileges_separation = true
}

resource "proxmox_virtual_environment_acl" "ansible_user_acl" {
  provider = bpg-proxmox

  path      = "/"
  role_id   = "Administrator"
  propagate = true
  user_id  = proxmox_virtual_environment_user.ansible_user.user_id
}

resource "proxmox_virtual_environment_acl" "ansible_api_acl" {
  provider = bpg-proxmox

  path      = "/"
  role_id   = "Administrator"
  propagate = true
  token_id  = proxmox_virtual_environment_user_token.ansible_api.id
}