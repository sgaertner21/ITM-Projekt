output "smb_nextcloud_user" {
  value = local.smb_nextcloud_user
}

output "smb_nextcloud_password" {
  value = random_password.nextcloud_smb_password.result
  sensitive = true
}