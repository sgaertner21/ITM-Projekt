terraform {
  # Define the required providers with their source and version.
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    bpg-proxmox = {
      source  = "bpg/proxmox"
      version = "0.69.0"
    }
    macaddress = {
      source  = "ivoronin/macaddress"
      version = "0.3.2"
    }
  }
}

# Generate a MAC address for WAN interface.
resource "macaddress" "wan_address" {
}

# Generate a MAC address for LAN interface.
resource "macaddress" "lan_address" {
}

# Create a cloud-init disk resource for configuring the VM at first boot.
resource "proxmox_cloud_init_disk" "ansible_cloud_init" {
  name     = var.vm_name
  pve_node = var.proxmox_node
  storage  = "local"

  # Encode meta data into YAML. Here, setting a unique instance-id using sha1.
  meta_data = yamlencode({
    instance-id = sha1(var.vm_name)
  })

  # Network configuration in YAML.
  network_config = yamlencode({
    version = 1
    config = [
      {
        type       = "physical"
        name       = "eth0"
        # Use the MAC address generated for WAN.
        mac_address: "${macaddress.wan_address.address}"
        subnets = [
          {
            type    = "static"
            # Set the IP address and subnet using provided variables.
            address = "${var.ip}/${var.subnet_cidr}"
            gateway = "${var.gateway}"
          }
        ]
      },
      {
        type    = "nameserver"
        # Configure DNS nameserver.
        address = [
          "${var.nameserver}"
        ]
      },
      {
        type       = "physical"
        name       = "eth1"
        # Use the MAC address generated for LAN.
        mac_address: "${macaddress.lan_address.address}"
        subnets = [
          merge(
            { type = var.network_config_typ_lan },
            # Complex: If LAN network type is static, merge additional IP config.
            var.network_config_typ_lan == "static" ? {
              address = "${var.ip_lan}/${var.subnet_cidr_lan}",
              gateway = "${var.gateway_lan}"
            } : {}
          )
        ]
      }
    ]
  })

  # Cloud-init user_data configuration to bootstrap the VM.
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
  write_files:
    - path: /home/ansible/.ssh/id_rsa
      content: |
        ${indent(6, tls_private_key.ansible.private_key_pem)}
      owner: ansible:ansible
      permissions: '0600'
      defer: true
    - path: /home/ansible/.ssh/id_rsa.pub
      content: |
        ${indent(6, tls_private_key.ansible.public_key_openssh)}
      owner: ansible:ansible
      permissions: '0644'
      defer: true
  EOT
}

# Define a Proxmox QEMU virtual machine using cloud-init.
resource "proxmox_vm_qemu" "ansible" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.proxmox_node

  # Hardware specifications.
  full_clone = false
  clone      = "ubuntu-server-noble"
  agent      = 1
  memory     = var.memory
  cores      = var.cores
  scsihw     = "virtio-scsi-pci"
  os_type    = "ubuntu"

  # Cloud-Init disk configuration as a CDROM drive.
  disk {
    storage = "local"
    type    = "cdrom"
    iso     = proxmox_cloud_init_disk.ansible_cloud_init.id
    format  = "qcow2"
    slot    = "ide0"
  }

  # Primary VM disk.
  disk {
    storage = "local"
    type    = "disk"
    size    = "20G"
    slot    = "virtio0"
  }

  # WAN network configuration.
  network {
    model   = "virtio"
    bridge  = "vmbr0"
    macaddr = macaddress.wan_address.address
  }

  # LAN network configuration.
  network {
    model   = "virtio"
    bridge  = "vmbr1"
    macaddr = macaddress.lan_address.address
  }

  # Connection details for remote provisioning.
  connection {
    host        = var.ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  # Remote execution provisioner to wait for cloud-init completion.
  provisioner "remote-exec" {
    inline = [
      "if [ ! -f /var/lib/cloud/instance/boot-finished ]; then echo 'Waiting for cloud-init...'; fi",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "echo 'cloud-init finished!'"
    ]
  }
}

# Use a Terraform data resource to run Ansible playbooks after the VM is fully set up.
resource "terraform_data" "run_ansible" {
  depends_on = [proxmox_vm_qemu.ansible]

  # Detect changes in the Ansible folder content.
  # Complex: Compute a hash from the concatenated file hashes in the Ansible directory and trigger replacement if any file changes.
  triggers_replace = sha1(join("", [for f in fileset("${path.root}/ansible/", "**") : filesha1("${path.root}/ansible/${f}")]))

  # Connection details for Ansible provisioning.
  connection {
    host        = var.ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  # Provisioner to ensure cloud-init has finished before running further commands.
  provisioner "remote-exec" {
    inline = [
      "if [ ! -f /var/lib/cloud/instance/boot-finished ]; then echo 'Waiting for cloud-init...'; fi",
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "rm -rf ~/ansible",
      "mkdir ~/ansible"
    ]
  }

  # Upload the Ansible folder to the remote host.
  provisioner "file" {
    source      = "${path.root}/ansible/"
    destination = "ansible"
  }

  # Upload the generated Proxmox inventory file using a template.
  provisioner "file" {
    content = templatefile("${path.module}/files/proxmox_inventory.tftpl", {
      proxmox_url         = var.proxmox_url
      proxmox_user        = proxmox_virtual_environment_user.ansible_user.user_id
      proxmox_token_id    = proxmox_virtual_environment_user_token.ansible_api.token_name
      proxmox_token_secret = regex(".*@.*!.*=(.*)", proxmox_virtual_environment_user_token.ansible_api.value)[0]
      ip_regex            = var.ip_regex
    })
    destination = "ansible/inventory_proxmox.yml"
  }

  # Run the Ansible playbook on the remote VM.
  provisioner "remote-exec" {
    inline = [
      "ansible-playbook -i ~/ansible/inventory_proxmox.yml ~/ansible/ansible-host/playbook.yml",
    ]
  }
}

# Generate an SSH key pair for the ansible user.
resource "tls_private_key" "ansible" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a Proxmox user for Ansible dynamic inventory management.
resource "proxmox_virtual_environment_user" "ansible_user" {
  provider = bpg-proxmox

  user_id = "ansible@pve"
  comment = "User for Ansible dynamic inventory"

  # Assign Administrator role with permissions to propagate to descendants.
  acl {
    path      = "/"
    role_id   = "Administrator"
    propagate = true
  }
}

# Create an API token for the previously created Proxmox user.
resource "proxmox_virtual_environment_user_token" "ansible_api" {
  provider = bpg-proxmox

  token_name            = "ansible"
  user_id               = proxmox_virtual_environment_user.ansible_user.id
  privileges_separation = true
}

# Create an ACL for the API token to grant full administrative permissions.
resource "proxmox_virtual_environment_acl" "ansible_api_acl" {
  provider = bpg-proxmox

  path      = "/"
  role_id   = "Administrator"
  propagate = true
  token_id  = proxmox_virtual_environment_user_token.ansible_api.id
}