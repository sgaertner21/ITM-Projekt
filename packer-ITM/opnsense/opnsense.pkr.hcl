# Ubuntu Server Focal Docker
# ---
# Packer Template to create an Ubuntu Server (Focal) with Docker on Proxmox

packer {
  required_plugins {
    name = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

variable "proxmox_node" {
    type = string
}

variable "proxmox_vm_id" {
    type = number
}

variable "vm_ip" {
    type = string
}

variable "vm_gateway" {
    type = string
}

variable "vm_subnet" {
    type = string
}

variable "vm_dns" {
    type = string
}

source "proxmox-iso" "opnsense" {

    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true

    # VM General Settings
    node = "${var.proxmox_node}"
    vm_id = "${var.proxmox_vm_id}"
    vm_name = "OPNsense-template"
    template_description = "OPNsense"

    boot_iso {
        iso_url = "https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.1/FreeBSD-14.1-RELEASE-amd64-disc1.iso"
        iso_checksum = "sha256:5321791bd502c3714850e79743f5a1aedfeb26f37eeed7cb8eb3616d0aebf86b"
        iso_storage_pool = "local"
        unmount = true
        index = 2
    }

    # VM System Settings
    qemu_agent = false
    onboot = true

    # VM Hard Disk Settings
    scsi_controller = "lsi"

    disks {
        disk_size = "20G"
        format = "qcow2"
        storage_pool = "local"
        type = "scsi"
        ssd = true
    }

    # VM CPU Settings
    cores = "2"
    
    # VM Memory Settings
    memory = "2048"

    # VM Network Settings
    network_adapters {
        model = "e1000"
        bridge = "vmbr0"
        firewall = "false"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local"
    
    # PACKER Boot Command
    boot_wait = "3s"
    boot_command = [
        "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar>",
        "<wait>1",
        "<wait20><enter>",
        "<wait><enter>",
        "<wait><enter>",
        "<wait><enter>",
        "<wait><enter>",
        "<wait10><enter>",
        "<wait><enter>",
        "<wait><spacebar><wait><enter>",
        "<wait><left><wait><enter>",
        "<wait70>",
        "opnsense<wait><enter>",
        "opnsense<wait><enter>",
        "<wait5><enter>",
        "<wait><enter>",
        "<wait><right><wait><enter>",
        "<wait>${var.vm_ip}<wait><down><wait>${var.vm_subnet}<wait><down><wait>${var.vm_gateway}<wait><tab>",
        "<wait><enter>",
        "<wait3><tab><wait><enter>",
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
    boot = "order=scsi0;ide2"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_host = "${var.vm_ip}"
    ssh_username = "root"
    ssh_password = "opnsense"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

build {

    name = "opnsense"
    sources = ["source.proxmox-iso.opnsense"]

    provisioner "file" {
        sources = [
            "./files/filter.xml",
            "./files/ssh.xml"
            ]
        destination = "/tmp/"
    }

    provisioner "shell" {
        script = "./scripts/opnsense_provision.sh"
    }

    provisioner "shell" {
        inline = [
            "pkg install -y py311-cloud-init-24.1.4_2",
            "echo 'cloudinit_enable=\"YES\"' >> /etc/rc.conf",
            "pkg install -y qemu-guest-agent",
            "echo 'qemu_guest_agent_enable=\"YES\"' >> /etc/rc.conf",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo cloud-init clean",
            "shutdown -p +20s"
        ]
        expect_disconnect = true
    }
}


#hostname
#utc