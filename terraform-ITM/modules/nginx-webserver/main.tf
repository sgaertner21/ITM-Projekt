# Define the required Terraform provider and its version.
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

# Create a VM resource on Proxmox for the nginx-webserver.
resource "proxmox_vm_qemu" "nginx-webserver" {
  name        = var.vm_name          # Name of the virtual machine.
  vmid        = var.vm_id            # Unique VM ID.
  target_node = var.proxmox_node     # Node in the Proxmox cluster to deploy the VM.

  # Hardware specifications:
  full_clone  = false                # Use linked clone instead of full clone.
  clone       = "ubuntu-server-noble" # Template/clone to be used for the VM.
  agent       = 1                    # Enable the QEMU guest agent.
  memory      = var.memory           # Memory allocation for the VM.
  cores       = var.cores            # Number of CPU cores.
  scsihw      = "virtio-scsi-pci"    # SCSI controller type.
  os_type     = "cloud-init"         # Specify that the operating system is set up via cloud-init.
  ciuser      = "ansible"            # Default user for cloud-init.
  sshkeys     = join("\n", var.ssh_keys)  # Combine SSH public keys, separated by new lines.
  
  # Configure IP settings:
  # Use DHCP if var.ip is set to "dhcp", otherwise configure static IP with gateway.
  ipconfig0   = var.ip == "dhcp" ? "ip=dhcp" : "ip=${var.ip},gw=${var.gateway}"

  # Cloud-Init disk configuration:
  disk {
    type    = "cloudinit"          # Disk used for cloud-init configuration.
    storage = "local"              # Storage pool.
    size    = "4M"                 # Small disk size.
    slot    = "ide0"               # Disk slot.
  }

  # Disk configuration for the VM:
  disk {
    storage = "local"              # Storage pool.
    type    = "disk"               # Disk type for VM.
    size    = "20G"                # VM disk size.
    slot    = "virtio0"            # Disk slot.
  }

  # Network configuration block:
  network {
    model  = "virtio"              # Use virtio network model.
    bridge = var.network_bridge     # Bridge interface to be used.
  }
}

# Prepare Ansible variables:
locals {
  ansible_variables = replace(jsonencode({
    var_hosts_webserver    = var.vm_name
    var_hosts_opnsense     = var.opnsense_vm_name
    var_opnsense_firewall  = var.opnsense_vm_name
    var_opnsense_api_key   = var.opnsense_api_key
    var_opnsense_api_secret = nonsensitive(var.opnsense_api_secret)
    var_webserver          = var.vm_name
    var_external_port      = tostring(var.external_port)
  }), "\"", "\\\"")
  # The replace function escapes quotes to ensure the JSON string is correctly passed as extra-vars to Ansible.
}

# Execute remote commands using a provisioner:
resource "terraform_data" "run_ansible" {
  depends_on = [proxmox_vm_qemu.nginx-webserver]  # Ensure the VM is created before running Ansible.

  # Set up the SSH connection to the host where Ansible is running.
  connection {
    host        = var.ansible_ip              # IP of the Ansible control machine.
    user        = "ansible"                   # Username for SSH.
    private_key = file("~/.ssh/id_rsa")         # Path to the private key for authentication.
  }

  # Run commands on the remote server.
  provisioner "remote-exec" {
    inline = [
      "cd ~/ansible",  
      # Build the command to fetch host inventory from Ansible.
      "command=\"ansible-inventory -i inventory_proxmox.yml --host ${var.vm_name} --yaml | grep ansible_host\"",
      # Loop until the host appears in the Ansible inventory. This helps handle any delays in the inventory update.
      "while ! eval $command; do echo \"Waiting for ansible inventory to build up...\"; sleep 5; done",
      "echo \"Host ${var.vm_name} found in ansible inventory!\"",
      # Run the Ansible playbook with the inventory and escaped extra variables.
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" nginx-webserver/playbook.yml"
    ]
  }
}