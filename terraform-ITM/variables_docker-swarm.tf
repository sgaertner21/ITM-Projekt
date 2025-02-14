variable "docker-swarm_start_vm_id" {
  description = "Start-ID für die Docker-Swarm-VMs"
  type = number  
}

variable "docker-swarm_vm_name" {
  description = "Name der VM"
  type = string
}

variable "docker-swarm_vm_ip" {
  description = "DHCP oder IP-Adresse der VM"
  type        = string
  default     = "dhcp"
}

variable "docker-swarm_vm_gateway" {
  description = "Gateway-IP-Adresse der VM"
  type        = string
  nullable    = true
  default     = null
}

variable "docker-swarm_vm_cores" {
  description = "Anzahl der CPU-Kerne"
  type = number
  default = 1
}

variable "docker-swarm_vm_memory" {
  description = "Arbeitsspeicher (MB)"
  type = number
  default = 1024
}

variable "docker-swarm_proxmox_node" {
  description = "Proxmox-Node, auf dem die VM läuft"
  type = string
}

variable "docker-swarm_external_port" {
  description = "Port, auf dem der Webserver von extern erreichbar ist"
  type = number
  default = 8443
}

variable "number_docker_swarm_manager_nodes" {
  description = "Anzahl der Manager-Nodes im Docker-Swarm"
  type = number
  default = 1
}

variable "number_docker_swarm_worker_nodes" {
  description = "Anzahl der Worker-Nodes im Docker-Swarm"
  type = number
  default = 2
}