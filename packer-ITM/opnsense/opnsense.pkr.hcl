# Packer Template for creating a FreeBSD VM on Proxmox that runs OPNsense

packer {
    # Specify required plugins for this build
    required_plugins {
        name = {
            version = "~> 1"  # Version constraint for the plugin
            source  = "github.com/hashicorp/proxmox"  # Plugin source location
        }
    }
}

# Define the ISO source to build the VM from
source "proxmox-iso" "opnsense" {

        # Proxmox Connection Settings
        proxmox_url = "${var.proxmox_api_url}"  # API URL for Proxmox
        username = "${var.proxmox_api_token_id}"  # Proxmox API token ID
        token = "${var.proxmox_api_token_secret}" # Proxmox API token secret
        insecure_skip_tls_verify = true  # Skip TLS verification if needed

        # VM General Settings
        node = "${var.proxmox_node}"  # Proxmox node where the VM will run
        vm_id = "${var.proxmox_vm_id}"  # Unique VM ID in Proxmox
        vm_name = "OPNsense-template"  # Name of the VM/template
        template_description = "OPNsense"  # Description of the template

        boot_iso {
                # URL to the FreeBSD installation ISO
                iso_url = "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.1/FreeBSD-14.1-RELEASE-amd64-disc1.iso"
                # Checksum to verify the ISO integrity
                iso_checksum = "sha256:5321791bd502c3714850e79743f5a1aedfeb26f37eeed7cb8eb3616d0aebf86b"
                iso_storage_pool = "local"  # Storage pool where the ISO is stored
                unmount = true  # Unmount ISO after boot
                index = 2  # Boot index order
        }

        # VM System Settings
        qemu_agent = false   # Disable QEMU agent
        onboot = true        # Start the VM automatically on boot

        # VM Hard Disk Settings
        scsi_controller = "lsi"  # Type of SCSI controller to use

        disks {
                disk_size = "20G"         # Disk size
                format = "qcow2"          # Disk format
                storage_pool = "local"    # Proxmox storage pool for the disk
                type = "scsi"             # Disk interface type
                ssd = true                # Indicate that this disk is on an SSD
        }

        # VM CPU Settings
        cores = "2"  # Number of CPU cores

        # VM Memory Settings
        memory = "2048"  # Amount of memory in MB

        # VM Network Settings
        network_adapters {
                model = "e1000"    # Network adapter model
                bridge = "vmbr0"   # Proxmox bridge for VM networking
                firewall = "false"  # Do not enable firewall on the adapter
        } 

        # VM Cloud-Init Settings
        cloud_init = true  # Enable cloud-init for post-install customization
        cloud_init_storage_pool = "local"  # Storage pool where cloud-init data is stored
        
        # PACKER Boot Command Settings
        boot_wait = "3s"  # Wait time before starting the boot command

        # Complex boot command sequence simulating keystrokes required for installation automation.
        boot_command = [
                # Send multiple spacebar keystrokes with pauses to ensure boot is registered
                "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar>",
                "<wait>1",  # Wait for one second
                "<wait20><enter>",  # Wait, then press enter
                "<wait><enter>",  # Continue with enter commands for subsequent steps
                "<wait><enter>",
                "<wait><enter>",
                "<wait><enter>",
                "<wait10><enter>",
                "<wait><enter>",
                # Commands for configuring installation properties
                "<wait><spacebar><wait><enter>",
                "<wait><left><wait><enter>",
                "<wait70>",
                # Type the string "opnsense" then enter; this could be setting a hostname or similar
                "opnsense<wait><enter>",
                "opnsense<wait><enter>",
                "<wait5><enter>",
                "<wait><enter>",
                "<wait><right><wait><enter>",
                # Network configuration: injecting variables for IP, subnet, gateway.
                "<wait>${var.vm_ip}<wait><down><wait>${var.vm_subnet}<wait><down><wait>${var.vm_gateway}<wait><tab>",
                "<wait><enter>",
                "<wait3><tab><wait><enter>",
                # Continue with DNS configuration using variable substitution.
                "<wait><down>${var.vm_dns}<wait><tab><wait><enter>",
                "<wait2><enter>",
                "<wait><enter>",
                "<wait><enter>",
                "<wait><enter>",
                "<wait><enter>",
                "<wait><enter>",
                "<wait><right><wait><enter>",
                "<wait><enter>",
                "<wait><left><wait><enter><wait3>sed -i '' 's/^#*PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config<enter><wait3>exit<wait><enter>",
                "<wait><enter>"
        ]
        # Set the boot device order for the VM
        boot = "order=scsi0;ide2"

        # PACKER Autoinstall Settings (currently commented)
        # http_directory = "http" 
        # Optionally, bind IP address and port for autoinstallation
        # http_bind_address = "0.0.0.0"
        # http_port_min = 8802
        # http_port_max = 8802

        # SSH connection settings to be used after installation.
        ssh_host = "${var.vm_ip}"  # IP address for SSH connection
        ssh_username = "root"      # SSH user for login
        ssh_password = "opnsense"  # SSH password

        ssh_timeout = "20m"  # Increase SSH timeout - useful if installation takes longer
}

build {
        name = "opnsense"  # Build name identifier
        sources = ["source.proxmox-iso.opnsense"]  # Reference the above-defined source

        # Provision files to the VM's /tmp/ directory
        provisioner "file" {
                sources = [
                        "./files/filter.xml",  # XML file for filtering configuration (likely for system setup)
                        "./files/ssh.xml"      # SSH configuration XML file
                ]
                destination = "/tmp/"
        }

        # Provision using a shell script for additional configuration steps
        provisioner "shell" {
                script = "./scripts/opnsense_provision.sh"  # Provisioning script to run after VM creation
        }

        # Inline shell commands for additional package installations and system cleanup.
        # Complex inline script: installs packages, enables services, cleans up and schedules a shutdown.
        provisioner "shell" {
                inline = [
                        "pkg install -y py311-cloud-init-24.1.4_2",  # Install specific cloud-init package version
                        "echo 'cloudinit_enable=\"YES\"' >> /etc/rc.conf",  # Enable cloud-init service at boot
                        "pkg install -y qemu-guest-agent",  # Install QEMU guest agent package
                        "echo 'qemu_guest_agent_enable=\"YES\"' >> /etc/rc.conf",  # Enable guest agent service at boot
                        "sudo rm /etc/ssh/ssh_host_*",  # Remove existing SSH host keys to regenerate upon next boot
                        "sudo truncate -s 0 /etc/machine-id",  # Truncate machine-id for uniqueness
                        "sudo cloud-init clean",  # Clean cloud-init state to ensure fresh provisioning
                        "shutdown -p +20s"  # Schedule a shutdown in 20 seconds after provisioning completes
                ]
                # Expect the connection to disconnect as the shutdown command is executed
                expect_disconnect = true
        }
}

# Additional commented notes:
# hostname - This placeholder comment might indicate where hostname configuration is intended.
# utc - Possibly a placeholder for timezone (UTC) configuration.