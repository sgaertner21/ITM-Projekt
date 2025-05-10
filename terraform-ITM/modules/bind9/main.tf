terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"           // Provider source for Proxmox
      version = "3.0.1-rc4"                 // Specific version of the Proxmox provider
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

resource "proxmox_vm_qemu" "bind9" {
  name         = var.vm_name                 // Virtual machine name from variable
  vmid         = var.vm_id                   // Unique VM ID from variable
  target_node  = var.proxmox_node            // Node in Proxmox where the VM will be created

  # Hardware specifications
  full_clone   = false                       // Use linked clone to save disk space
  clone        = "ubuntu-server-noble"       // Template VM to clone from
  agent        = 1                           // Enable QEMU guest agent (set to 1 for enabled)
  memory       = var.memory                  // Allocated memory in MB from variable
  cores        = var.cores                   // Number of CPU cores from variable
  scsihw       = "virtio-scsi-pci"           // Type of SCSI controller
  os_type      = "cloud-init"                // Cloud-init OS type
  ciuser       = "ansible"                   // Default user for cloud-init
  sshkeys      = join("\n", var.ssh_keys)    // SSH keys joined by newline from variable
  ipconfig0    = "ip=${var.ip},gw=${var.gateway}" // IP configuration: IP and gateway

  # Disk for Cloud-Init configuration
  disk {
    type    = "cloudinit"                   // Disk role for cloud-init data
    storage = "local"                       // Storage location
    slot    = "ide0"                        // Disk slot
  }

  # Primary disk for the virtual machine
  disk {
    storage = "local"                       // Storage location
    type    = "disk"                        // Disk type
    size    = "20G"                         // Disk size of 20 GB
    slot    = "virtio0"                     // Disk slot for VM disk
  }

  # Network configuration
  network {
    model  = "virtio"                       // Network interface model
    bridge = var.network_bridge              // Bridge name provided as a variable
  }
}

resource "random_password" "ddns_domainkey" {
  length = 64
}

locals {
  ansible_variables = replace(replace(jsonencode({
    var_hosts_dns             = var.vm_name              // DNS host name for Ansible variable
    var_primary_dns_host      = var.vm_name              // Primary DNS host name (duplicate for clarity)
    var_zone_network_address  = "172.18.0"               // Network address for DNS zone configuration
    var_forwarders            = [ "9.9.9.9", "1.1.1.1" ] // DNS forwarders
    var_opnsense_ip           = var.opnsense_ip          // OPNsense IP address variable
    var_ddns_domainkey = nonsensitive(random_password.ddns_domainkey.base64)
    var_opnsense_ip = var.opnsense_ip
    var_hosts_opnsense        = var.opnsense_vm_name     // OPNsense VM name variable
  }), "\"", "\\\""), "$", "\\$") // Replace quotes for proper formatting in shell command usage
}

resource "terraform_data" "run_ansible" {
  depends_on = [proxmox_vm_qemu.bind9]        // Ensure the VM creation is complete before this runs

  connection {
    host        = var.ansible_ip              // Host for remote connection, provided by variable
    user        = "ansible"                   // Remote username for SSH
    private_key = file("~/.ssh/id_rsa")       // Path to the SSH private key
  }

  provisioner "remote-exec" {
    inline = [
      "cd ~/ansible",                        // Change to the ansible directory
      "command=\"ansible-inventory -i inventory_proxmox.yml --host ${var.vm_name} --yaml | grep ansible_host\"",
                                              // Build the command to check if the host exists in the Ansible inventory
      "while ! eval $command; do echo \"Waiting for ansible inventory to build up...\"; sleep 5; done",
                                              // Loop until the host is found in the Ansible inventory
      "echo \"Host ${var.vm_name} found in ansible inventory!\"",
                                              // Notify once the host is found
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" dns/playbook.yml"
                                              // Execute the Ansible playbook with extra variables and SSH options
    ]
  }
}