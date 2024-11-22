resource "proxmox_vm_qemu" "ansible" {
  name = var.vm_name
  vmid = var.vm_id
  target_node = var.proxmox_node

  # Hardware-Spezifikationen
  full_clone = false
  clone = "ubuntu-server-noble"
  agent = 1
  memory = var.memory
  cores = var.cores
  scsihw = "virtio-scsi-pci"
  os_type = "cloud-init"
  ciuser = "ansible"
  cipassword = "ansible"
  nameserver = "1.1.1.1"
  ipconfig0 = "ip=172.16.0.5/16,gw=172.16.0.1"

  # Speicher Cloud-Init
  disk {
    type = "cloudinit"
    storage = "local"
    size = "4M"
    slot = "ide0"
  }

  # Speicher VM
  disk {
    storage = "local"
    type = "disk"
    size = "20G"
    slot = "virtio0"
  }

  # Netzwerk
  network {
    model = "virtio"
    bridge = "vmbr0"
  }
}