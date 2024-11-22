resource "proxmox_vm_qemu" "test-server-1" {
  name = "test-server-1"
  target_node = "proxmox-ve"

  full_clone = false
  clone = "ubuntu-server-noble"
  agent = 1
  memory = 1024
  cores = 1
  scsihw = "virtio-scsi-pci"
  os_type = "cloud-init"
  ciuser = "justin"
  cipassword = "justin"
  nameserver = "1.1.1.1"
  ipconfig0 = "ip=172.16.0.6/16,gw=172.16.0.1"

  disk {
    type = "cloudinit"
    storage = "local"
    size = "4M"
    slot = "ide0"
  }

  disk {
    storage = "local"
    type = "disk"
    size = "20G"
    slot = "virtio0"
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
  }
}