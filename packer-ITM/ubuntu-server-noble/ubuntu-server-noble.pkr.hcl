# Ubuntu Server Noble
# ---
# Packer Template to create an Ubuntu Server (Noble) on Proxmox

# Packer configuration block to define required plugins
packer {
    required_plugins {
        name = {
            version = "~> 1"                           # Required version of the Proxmox plugin
            source  = "github.com/hashicorp/proxmox"   # Source location of the Proxmox plugin
        }
    }
}

# Define the VM Template details for Proxmox using the proxmox-iso source type.
source "proxmox-iso" "ubuntu-server-noble" {

        # Proxmox Connection Settings:
        # The URL of the Proxmox API, the token ID and secret for authentication.
        proxmox_url = "${var.proxmox_api_url}"
        username = "${var.proxmox_api_token_id}"
        token = "${var.proxmox_api_token_secret}"
        # Optional: Skip TLS Verification if needed (not recommended for production)
        insecure_skip_tls_verify = true
        
        # Define general settings for the VM in Proxmox:
        node = "${var.proxmox_node}"                           # Proxmox node where the VM will be created
        vm_id = "${var.proxmox_vm_id}"                         # Unique VM ID provided as a variable
        vm_name = "ubuntu-server-noble"                        # Name of the template VM
        template_description = "Ubuntu Server Noble Image"   # Description for the VM template

        # Boot ISO Settings:
        # This block defines the ISO image details used to install the OS.
        boot_iso {
                iso_url = "https://releases.ubuntu.com/noble/ubuntu-24.04.1-live-server-amd64.iso"  # URL to download the Ubuntu ISO
                iso_checksum = "sha256:e240e4b801f7bb68c20d1356b60968ad0c33a41d00d828e74ceb3364a0317be9"  # Checksum to verify the ISO file
                iso_storage_pool = "local"        # Storage pool where the ISO will be stored on Proxmox
                unmount = true                    # Unmount the ISO after installation
                index = 2                         # Index to show boot order if multiple ISOs are attached
        }

        # Enable QEMU guest agent for improved interaction between host and guest VM
        qemu_agent = true

        # Define disk settings for the VM:
        scsi_controller = "virtio-scsi-pci"   # SCSI controller type for the VM

        disks {
                disk_size = "20G"                # Disk size allocated to the VM template
                format = "qcow2"                 # Disk format (qcow2 supports snapshots)
                storage_pool = "local"           # Proxmox storage pool for the disk
                type = "virtio"                  # Disk interface type
        }

        # CPU Settings:
        cores = "2"                          # Number of CPU cores allocated to the VM

        # Memory Settings:
        memory = "2048"                      # Memory allocated to the VM in MB

        # Network Settings:
        network_adapters {
                model = "virtio"                # Network card model
                bridge = "vmbr0"                # Proxmox bridge for network connection
                firewall = "false"              # Disable firewall at the adapter level
        }

        # Cloud-Init Integration Settings:
        cloud_init = true                     # Enable cloud-init for initial configuration
        cloud_init_storage_pool = "local"     # Storage pool where cloud-init data will be stored

        # Packer Boot Commands:
        # These commands are injected during the boot process to adjust boot parameters
        boot_command = [
                "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
                "e<wait>",
                "<down><down><down><end>",
                "<bs><bs><bs><bs><bs>",
                " ip=${var.vm_ip}::${var.vm_gateway}:${var.vm_subnet}::::${var.vm_dns}",
                " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
                " ---",
                "<wait>",
                "<f10>"
        ]
        # Boot order: boot from the virtio0 disk first then ide2 if needed.
        boot = "order=virtio0;ide2"
        boot_wait = "10s"                    # Wait time before boot commands are executed

        # HTTP Server directory for Autoinstall configuration:
        http_directory = "http"              # Directory to serve additional files (e.g., autoinstall config)
        # Optionally bind HTTP server to specific IP and port:
        # http_bind_address = "0.0.0.0"
        # http_port_min = 8802
        # http_port_max = 8802

        # SSH Configuration for communication with the VM:
        ssh_username = "packer-user"
        ssh_private_key_file = "${path.root}/.ssh/id_rsa"

        # Increase SSH timeout since OS installations may take longer.
        ssh_timeout = "20m"
}

# Build Definition to create the VM Template:
build {

        name = "ubuntu-server-noble"
        sources = ["source.proxmox-iso.ubuntu-server-noble"]

        # Provisioner to wait until cloud-init finishes booting:
        provisioner "shell" {
                inline = [
                        "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
                        # Cleanup SSH keys to force regeneration
                        "sudo rm /etc/ssh/ssh_host_*",
                        # Clear machine ID to avoid conflicts in cloned VMs
                        "sudo truncate -s 0 /etc/machine-id",
                        # Remove unused packages and clean up to reduce image size
                        "sudo apt -y autoremove --purge",
                        "sudo apt -y clean",
                        "sudo apt -y autoclean",
                        # Clean cloud-init state for new VM instances
                        "sudo cloud-init clean",
                        # Remove default network configuration that might interfere with cloud-init networking
                        "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
                        "sudo sync"
                ]
        }

        # Provisioner to upload a custom configuration file for Proxmox cloud-init integration:
        provisioner "file" {
                source = "${path.root}/files/99-pve.cfg"        # Local file on host to transfer
                destination = "/tmp/99-pve.cfg"                   # Destination on the VM
        }

        # Provisioner to copy the uploaded file to the final location:
        provisioner "shell" {
                inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
        }

        # Optional breakpoint to pause the provisioning for manual intervention if required:
        provisioner "breakpoint" {
                disable = true                                  # Disabled by default; set to false to pause the process
                note = "Run shell commands manually"            # Note to help identify the pause point
        }

        # Remove the .ssh directory from the VM after provisioning:
        provisioner "shell" {
                inline = ["rm -r .ssh"]
        }

        # Additional provisioning scripts or steps can be added here if necessary
}
