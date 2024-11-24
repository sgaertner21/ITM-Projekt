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
  nameserver = var.nameserver
  ipconfig0 = "ip={var.ip},gw={var.gateway}"

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