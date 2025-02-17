locals {
  ansible_variables = replace(jsonencode({
    var_fileserver_name = var.fileserver_vm_name
    var_smb_nextcloud_user = var.smb_nextcloud_user
    var_smb_nextcloud_password = nonsensitive(var.smb_nextcloud_password)
    var_nextcloud_mount_datadir = "/mnt/nextcloud_data"
    var_mount_volumes_dir = "/mnt/docker_volumes"
    var_database_password = nonsensitive(random_password.database_password.result)
    var_fulltextsearch_password = nonsensitive(random_password.fulltextsearch_password.result)
    var_imaginary_secret = nonsensitive(random_password.imaginary_secret.result)
    var_nc_domain = "nextcloud.itm.internal"
    var_nextcloud_password = nonsensitive(random_password.nextcloud_password.result)
    var_onlyoffice_secret = nonsensitive(random_password.onlyoffice_secret.result)
    var_recording_secret = nonsensitive(random_password.recording_secret.result)
    var_redis_password = nonsensitive(random_password.redis_password.result)
    var_signaling_secret = nonsensitive(random_password.signaling_secret.result)
    var_talk_internal_secret = nonsensitive(random_password.talk_internal_secret.result)
    var_turn_secret = nonsensitive(random_password.turn_secret.result)
    var_whiteboard_secret = nonsensitive(random_password.whiteboard_secret.result)
  }), "\"", "\\\"")
}

resource "random_password" "database_password" {
  length = 30
  special = false
}

resource "random_password" "fulltextsearch_password" {
  length = 30
  special = false
}

resource "random_password" "nextcloud_password" {
  length = 12
  special = false
}

resource "random_password" "redis_password" {
  length = 30
  special = false
}

resource "random_password" "imaginary_secret" {
  length = 30
  special = false
}

resource "random_password" "onlyoffice_secret" {
  length = 30
  special = false
}

resource "random_password" "recording_secret" {
  length = 30
  special = false
}

resource "random_password" "signaling_secret" {
  length = 30
  special = false
}

resource "random_password" "talk_internal_secret" {
  length = 30
  special = false
}

resource "random_password" "turn_secret" {
  length = 30
  special = false
}

resource "random_password" "whiteboard_secret" {
  length = 30
  special = false
}

resource "terraform_data" "run_ansible" {

  connection {
    host        = var.ansible_ip
    user        = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
    "cd ~/ansible",
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" nextcloud/playbook.yml"
    ]
  }
}