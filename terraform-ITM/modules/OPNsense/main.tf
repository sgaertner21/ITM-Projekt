# Terraform block to configure the required providers.
terraform {
  required_providers {
    telmate-proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
    bpg-proxmox = {
      source  = "bpg/proxmox"
      version = "0.69.0"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "1.2.1"
    }
  }
}

# Create a Linux bridge network on the Proxmox environment for OPNsense LAN.
resource "proxmox_virtual_environment_network_linux_bridge" "OPNsense_bridge" {
  provider  = bpg-proxmox

  # Name of the Proxmox node.
  node_name = var.proxmox_node
  # Bridge name variable.
  name      = var.proxmox_ve_network_bridge_lan
  # LAN IP address with /24 CIDR.
  address   = "${var.proxmox_lan_ip}/24"
  # Network description.
  comment   = "Internal LAN network"
}

# Provision a cloud-init disk for the OPNsense VM.
resource "proxmox_cloud_init_disk" "OPNsense_cloud_init" {
  provider = telmate-proxmox

  # Name identifier for the cloud-init disk.
  name     = "cloudinit"
  pve_node = var.proxmox_node
  storage  = "local"
  meta_data = yamlencode({
    instance_id    = sha1(var.vm_name)             # Unique instance id using sha1 hash of VM name.
    local_hostname = var.vm_name                   # Setting the hostname of the VM.
  })
  # Render user-data from template with required variables.
  user_data = templatefile("${path.module}/files/user_data.tftpl", {
    vm_network_interface_lan = var.vm_network_interface_lan
    vm_network_interface_wan = var.vm_network_interface_wan
    vm_lan_ip                = var.vm_lan_ip
    vm_wan_ip                = var.vm_wan_ip
    wan_gateway              = var.wan_gateway
    vm_dns_server            = var.vm_dns_server
    vm_wan_subnet_cidr       = "24"
    ssh_keys_base64          = base64encode(join("\r\n", var.ssh_keys))  # Base64 encoded SSH keys.
  })
}

# Create the Proxmox QEMU VM resource for OPNsense.
resource "proxmox_vm_qemu" "OPNsense_vm" {
  provider = telmate-proxmox

  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.proxmox_node

  # Hardware specifications
  full_clone = true
  clone      = "OPNsense-template"
  agent      = 1
  memory     = var.memory
  cores      = var.cores
  scsihw     = "lsi"
  onboot     = "true"

  # Attach cloud-init disk as a CD-ROM device.
  disk {
    storage = "local"
    type    = "cdrom"
    # Reference cloud-init disk provider id.
    iso     = "${proxmox_cloud_init_disk.OPNsense_cloud_init.id}"
    format  = "qcow2"
    slot    = "ide0"
  }

  # Define a regular disk for the virtual machine.
  disk {
    storage    = "local"
    type       = "disk"
    size       = "20G"
    format     = "qcow2"
    slot       = "scsi0"
    emulatessd = true
  }

  # Configure boot order.
  boot = "order=scsi0"

  # Network interfaces configuration:
  # First network for WAN.
  network {
    model  = "e1000"
    bridge = var.proxmox_ve_network_bridge_wan
  }
  # Second network for LAN referencing the created Linux bridge.
  network {
    model  = "e1000"
    bridge = proxmox_virtual_environment_network_linux_bridge.OPNsense_bridge.name
  }

  # Connection details for further remote execution on the VM.
  connection {
    host        = var.vm_wan_ip
    user        = "root"
    private_key = file("~/.ssh/id_rsa")
    timeout     = "10m"
  }

  # Provisioner block to wait for cloud-init completion:
  provisioner "remote-exec" {
    inline = [
      "if [ ! -f /var/lib/cloud/instance/boot-finished ]; then echo 'Waiting for cloud-init...'; fi",
      # Loop until the cloud-init boot finish file is present.
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do sleep 1; done",
      "echo 'cloud-init finished!'"
    ]
  }
}

# Local block that prepares ansible variables by JSON encoding and escaping.
locals {
  ansible_variables = replace(replace(jsonencode({
    var_hosts_opnsense = var.vm_name
    var_ansible_public_ssh_key = chomp(var.ansible_ssh_key)
    var_ansible_opnsense_api_key = random_id.opnsense_api_key.b64_std
    var_ansible_opnsense_api_secret_hash = nonsensitive(htpasswd_password.opnsense_api_secret_hash.sha512)
    var_dhcp_dns_server = var.dhcp_dns_server
  }), "\"", "\\\""), "$", "\\$")
  # Note: used replace functions to escape quotes and $ symbols for shell command usage.
}

# Terraform resource that runs Ansible after the VM is provisioned.
resource "terraform_data" "run_ansible" {
  depends_on = [ proxmox_vm_qemu.OPNsense_vm ]

  # Connection settings for the ansible machine.
  connection {
    host        = var.ansible_ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  # Remote-exec provisioner to run Ansible commands:
  provisioner "remote-exec" {
    inline = [
      "cd ~/ansible",
      # Build the Ansible inventory lookup command. Grep for ansible_host field.
      "command=\"ansible-inventory -i inventory_proxmox.yml --host ${var.vm_name} --yaml | grep ansible_host\"",
      # Wait until the host is found in the Ansible inventory.
      "while ! eval $command; do echo \"Waiting for ansible inventory to build up...\"; sleep 5; done",
      "echo \"Host ${var.vm_name} found in ansible inventory!\"",
      # Run the Ansible playbook with the extra variables passed.
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" opnsense/playbook.yml"
    ]
  }
}

# Generate a random id to be used as the API key for OPNsense.
resource "random_id" "opnsense_api_key" {
  byte_length = 60
}

# Generate random bytes for OPNsense API secret.
resource "random_bytes" "opnsense_api_secret" {
  length = 30
}

# Create a hashed password for the API secret using htpasswd.
resource "htpasswd_password" "opnsense_api_secret_hash" {
  password = random_bytes.opnsense_api_secret.base64
}
