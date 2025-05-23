variable "nginx-webserver_vm_name" {
  description = "Name der VM"
  type = string
}

variable "nginx-webserver_vm_ip" {
  description = "DHCP oder IP-Adresse der VM"
  type        = string
  default     = "dhcp"
}

variable "nginx-webserver_vm_gateway" {
  description = "Gateway-IP-Adresse der VM"
  type        = string
  nullable    = true
  default     = null
}

variable "nginx-webserver_vm_cores" {
  description = "Anzahl der CPU-Kerne"
  type = number
  default = 1
}

variable "nginx-webserver_vm_memory" {
  description = "Arbeitsspeicher (MB)"
  type = number
  default = 1024
}

variable "nginx-webserver_proxmox_node" {
  description = "Proxmox-Node, auf dem die VM läuft"
  type = string
}

variable "nginx-webserver_vm_id" {
  description = "ID der VM"
  type = number
  nullable = true
}

variable "nginx-webserver_external_port" {
  description = "Port, auf dem der Webserver von extern erreichbar ist"
  type = number
  default = 8080
}