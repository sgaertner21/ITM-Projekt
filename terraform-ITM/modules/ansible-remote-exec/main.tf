resource "terraform_data" "ansible_remote_exec" {

  connection {
    host = module.ansible.ip
    user = "ansible"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = var.inline_commands
  }
}