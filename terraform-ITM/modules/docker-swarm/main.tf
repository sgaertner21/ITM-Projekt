# Define the Terraform block with required providers
terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

# Resource definition for creating Proxmox QEMU VMs for Docker Swarm
resource "proxmox_vm_qemu" "docker-swarm" {
  # Loop over the provided map of VMs from the variable "docker_vms"
  for_each = var.docker_vms

  # Basic VM configuration
  name        = each.key                         # Use the key as the VM name
  vmid        = each.value.vm_id                 # Unique VM ID from variable
  target_node = each.value.proxmox_node          # Target Proxmox node
  
  # Hardware specifications
  full_clone  = false                            # Do not use full clone
  clone       = "ubuntu-server-noble"            # Clone source image name
  agent       = 1                                # Enable QEMU guest agent
  memory      = each.value.memory                # Memory allocation per VM
  cores       = each.value.cores                 # Number of CPU cores
  scsihw      = "virtio-scsi-pci"                # SCSI hardware type setting
  os_type     = "cloud-init"                     # Operative system type is cloud-init
  ciuser      = "ansible"                        # Default user for cloud-init configuration
  sshkeys     = join("\n", each.value.ssh_keys)  # Join SSH keys with newline
  # Dynamic IP configuration: use DHCP or assign static IP with gateway
  ipconfig0   = each.value.ip == "dhcp" ? "ip=dhcp" : "ip=${each.value.ip},gw=${each.value.gateway}"
  tags        = join(",", each.value.tags)       # Join provided tags with comma

  # Define disk for Cloud-Init configuration
  disk {
    type    = "cloudinit"
    storage = "local"
    size    = "4M"
    slot    = "ide0"
  }

  # Define the main disk for the VM
  disk {
    storage = "local"
    type    = "disk"
    size    = "20G"
    slot    = "virtio0"
  }

  # Network configuration for the VM
  network {
    model  = "virtio"
    bridge = each.value.network_bridge         # Specify the network bridge
  }
}

# Note: The following commented lines appear to be additional configuration variables for playbook parameters.
#  "var_hosts_webserver=${var.vm_name}",
#  "var_hosts_opnsense=${var.opnsense_vm_name}",
#  "var_opnsense_firewall=${var.opnsense_vm_name}",
#  "var_opnsense_api_key=${var.opnsense_api_key}",
#  "var_opnsense_api_secret=${nonsensitive(var.opnsense_api_secret)}",
#  "var_webserver=${var.vm_name}",
#  "var_external_port=${var.external_port}",

# Provisioning resource to run Ansible after provisioning VMs
resource "terraform_data" "run_ansible" {
  # Wait for all "docker-swarm" VMs to be created before running this resource
  depends_on = [proxmox_vm_qemu.docker-swarm]

  # SSH connection configuration to the Ansible host
  connection {
    host        = var.ansible_ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  # Remote execution provisioner block that runs multiple commands
  provisioner "remote-exec" {
    inline = concat(
      ["cd ~/ansible"],  # Change into the Ansible directory

      # For every VM in docker_vms, generate commands to verify its entry in the Ansible inventory.
      flatten([for vm_name in keys(var.docker_vms) : [
        # Generate a command to query the inventory for the VM's host details
        "command=\"ansible-inventory -i inventory_proxmox.yml --host ${proxmox_vm_qemu.docker-swarm[vm_name].name} --yaml | grep ansible_host\"",
        # Loop until the host appears in the inventory; wait and retry every 5 seconds.
        "while ! eval $command; do echo \"Waiting for ansible inventory to build up...\"; sleep 5; done",
        # Confirmation message once the host is found in the inventory.
        "echo \"Host ${proxmox_vm_qemu.docker-swarm[vm_name].name} found in ansible inventory!\""
      ]]),

      # Finally, execute the Ansible playbook with the generated inventory.
      ["ansible-playbook -i inventory_proxmox.yml --ssh-extra-args=\"-o StrictHostKeyChecking=no\" docker-swarm/playbook.yml"]
    )
  }
}
