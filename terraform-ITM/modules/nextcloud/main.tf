# Local block to define variables for Ansible
locals {
  # Generate a JSON string of key-value pairs containing various variables for Ansible.
  # The `replace` function escapes quotes in the resulting JSON string.
  ansible_variables = replace(jsonencode({
    # Mapping Terraform variables and generated passwords to names expected by Ansible.
    var_fileserver_name         = var.fileserver_vm_name
    var_smb_nextcloud_user      = var.smb_nextcloud_user
    # Wrap sensitive values with nonsensitive() to mark them non-sensitive for transmission.
    var_smb_nextcloud_password  = nonsensitive(var.smb_nextcloud_password)
    var_nextcloud_mount_datadir = "/mnt/nextcloud_data"
    var_mount_volumes_dir       = "/mnt/docker_volumes"
    var_database_password       = nonsensitive(random_password.database_password.result)
    var_fulltextsearch_password = nonsensitive(random_password.fulltextsearch_password.result)
    var_imaginary_secret        = nonsensitive(random_password.imaginary_secret.result)
    var_nc_domain               = "nextcloud.itm.internal"
    var_nextcloud_password      = nonsensitive(random_password.nextcloud_password.result)
    var_onlyoffice_secret       = nonsensitive(random_password.onlyoffice_secret.result)
    var_recording_secret        = nonsensitive(random_password.recording_secret.result)
    var_redis_password          = nonsensitive(random_password.redis_password.result)
    var_signaling_secret        = nonsensitive(random_password.signaling_secret.result)
    var_talk_internal_secret    = nonsensitive(random_password.talk_internal_secret.result)
    var_turn_secret             = nonsensitive(random_password.turn_secret.result)
    var_whiteboard_secret       = nonsensitive(random_password.whiteboard_secret.result)
  }), "\"", "\\\"")
}

# Generate a random password for the database
resource "random_password" "database_password" {
  length  = 30  # Specify length of the password
  special = false  # Exclude special characters from the password
}

# Generate a random password for the full-text search feature
resource "random_password" "fulltextsearch_password" {
  length  = 30
  special = false
}

# Generate a random password for Nextcloud
resource "random_password" "nextcloud_password" {
  length  = 12  # Nextcloud password has a shorter length requirement
  special = false
}

# Generate a random password for Redis
resource "random_password" "redis_password" {
  length  = 30
  special = false
}

# Generate a random "imaginary" secret; purpose can be defined by the user
resource "random_password" "imaginary_secret" {
  length  = 30
  special = false
}

# Generate a random secret for OnlyOffice
resource "random_password" "onlyoffice_secret" {
  length  = 30
  special = false
}

# Generate a random secret for recording functionality
resource "random_password" "recording_secret" {
  length  = 30
  special = false
}

# Generate a random secret for signaling functionality
resource "random_password" "signaling_secret" {
  length  = 30
  special = false
}

# Generate a random secret for internal talk feature
resource "random_password" "talk_internal_secret" {
  length  = 30
  special = false
}

# Generate a random secret for TURN (Traversal Using Relays around NAT)
resource "random_password" "turn_secret" {
  length  = 30
  special = false
}

# Generate a random secret for the whiteboard feature
resource "random_password" "whiteboard_secret" {
  length  = 30
  special = false
}

# Resource to run an Ansible playbook via remote-exec provisioner
resource "terraform_data" "run_ansible" {

  connection {
    # Host to connect to.
    host = var.ansible_ip
    # SSH user for connection.
    user = "ansible"
    # Private key used for SSH login.
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "cd ~/ansible",  # Change to the ansible directory on the remote host.
      # Execute the ansible playbook with the inventory, extra-vars (rendered JSON from locals), 
      # and custom SSH arguments to disable host key checking.
      "ansible-playbook -i inventory_proxmox.yml --extra-vars \"${local.ansible_variables}\" --ssh-extra-args=\"-o StrictHostKeyChecking=no\" nextcloud/playbook.yml"
    ]
  }
}