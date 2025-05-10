# Terraform configuration block specifying required providers.
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"           # Proxmox provider from Telmate.
      version = "3.0.1-rc4"                  # Specific provider version.
    }
  }
}

# Resource to create a QEMU virtual machine in Proxmox for the file server.
resource "proxmox_vm_qemu" "fileserver" {
  name        = var.vm_name                # Name of the VM derived from variable.
  vmid        = var.vm_id                  # Unique VM identifier.
  target_node = var.proxmox_node           # Target Proxmox node on which VM is deployed.

  # Hardware specifications
  full_clone  = false                      # Use linked clone instead of full clone.
  clone       = "ubuntu-server-noble"      # Base image/template to clone from.
  agent       = 1                          # Enable the QEMU guest agent.
  memory      = var.memory                 # Memory allocation for the VM.
  cores       = var.cores                  # Number of CPU cores allocated.
  scsihw      = "virtio-scsi-pci"          # SCSI hardware controller type.
  os_type     = "cloud-init"               # Indicate that the OS uses Cloud-Init.
  ciuser      = "ansible"                  # Default user for cloud-init provisioning.
  sshkeys     = join("\n", var.ssh_keys)   # SSH keys to be injected into the VM.
  
  # Network configuration: Use conditional expression to support DHCP or static IP.
  ipconfig0   = var.ip == "dhcp" ? "ip=dhcp" : "ip=${var.ip},gw=${var.gateway}"

  # Cloud-Init drive for storing instance metadata.
  disk {
    type    = "cloudinit"                # Specify disk type as Cloud-Init.
    storage = "local"                    # Storage location.
    size    = "4M"                       # Small size for Cloud-Init config.
    slot    = "ide0"                     # Disk slot identifier.
  }

  # Disk for primary VM storage.
  disk {
    storage = "local"                    # Local storage.
    type    = "disk"                     # Disk type.
    size    = "80G"                      # Size of the disk.
    slot    = "virtio0"                  # Disk slot identifier.
  }

  # Disk for additional VM storage.
  disk {
    storage = "local"
    type    = "disk"
    size    = "300G"
    slot    = "virtio1"
  }

  # Network interface configuration.
  network {
    model  = "virtio"                    # Use virtio network driver.
    bridge = var.network_bridge           # Network bridge variable.
  }
}

# Resource to generate a random password for Nextcloud SMB user.
resource "random_password" "nextcloud_smb_password" {
  length  = 32                         # Specify password length.
  special = false                      # Excluding special characters.
}

# Local values block for computed variables and complex interpolations.
locals {
  smb_nextcloud_user = "nextcloud-user"   # Username for Nextcloud SMB access.

  # Create a JSON string encapsulating various Ansible variables needed for playbook execution.
  ansible_variables = replace(replace(jsonencode({
    var_hosts_fileserver = var.vm_name,      # File server host name.
    var_samba_groups     = [                 # Define Samba groups.
      {
        name = "nextcloud-group"
      }
    ],
    var_samba_users = [                      # Define Samba users.
      {
        name     = local.smb_nextcloud_user,   # Samba user name.
        password = nonsensitive(random_password.nextcloud_smb_password.result), # Random password.
        group    = "nextcloud-group"           # User group association.
      }
    ],
    var_nextcloud_data_owner_group = "nextcloud-group",  # Ownership group for Nextcloud data.
    var_nextcloud_data_valid_users = "@nextcloud-group", # Valid users tag for Nextcloud data.
    var_nextcloud_data_write_list  = "@nextcloud-group", # Write permission list.
    var_docker_volumes_owner_group = "nextcloud-group",  # Docker volumes ownership group.
    var_docker_volumes_valid_users = "@nextcloud-group", # Valid users for Docker volumes.
    var_docker_volumes_write_list  = "@nextcloud-group", # Write permission list.
  }), "\"", "\\\""), "$", "\\$")   # Escapes double quotes for proper shell injection.
}

# Resource to run Ansible playbook remotely after VM creation.
resource "terraform_data" "run_ansible" {
  depends_on = [proxmox_vm_qemu.fileserver]    # Ensure the VM creation is complete.

  # Connection block for remote execution using Ansible user and SSH key.
  connection {
    host        = var.ansible_ip         # IP address as configured in variable.
    user        = "ansible"              # Remote user to connect with.
    private_key = file("~/.ssh/id_rsa")    # SSH private key retrieval.
  }

  # Provisioner block to execute remote commands.
  provisioner "remote-exec" {
    inline = [
      "cd ~/ansible",   # Change to the ansible directory.
      # Build a command to verify that the inventory includes our file server.
      "command=\"ansible-inventory -i inventory_proxmox.yml --host ${var.vm_name} --yaml | grep ansible_host\"",
      # Poll until the file server host appears in the ansible inventory.
      "while ! eval $command; do echo \"Waiting for ansible inventory to build up...\"; sleep 5; done",
      "echo \"Host ${var.vm_name} found in ansible inventory!\"",
      # Execute the playbook with extra variables, bypassing SSH host key checks.
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" fileserver/playbook.yml"
    ]
  }
}