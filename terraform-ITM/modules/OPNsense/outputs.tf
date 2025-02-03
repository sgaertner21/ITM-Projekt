output "opnsense_api_key" {
  value = random_id.opnsense_api_key.b64_std
}

output "opnsense_api_secret" {
  value = random_bytes.opnsense_api_secret.base64
}