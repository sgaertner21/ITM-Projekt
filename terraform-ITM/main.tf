# Terraform block to specify required providers
terraform {
  required_providers {
    # Telmate Proxmox provider configuration
    telmate-proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc4"
    }
    # bpg Proxmox provider configuration
    bpg-proxmox = {
      source  = "bpg/proxmox"
      version = "0.69.0"
    }
  }
}

# Define the telmate-proxmox provider with connection details
provider "telmate-proxmox" {
  pm_api_url        = "${var.proxmox_url}/api2/json"        # API endpoint constructed using the proxmox_url variable
  pm_api_token_id   = var.proxmox_api_token_id             # API Token ID from variables
  pm_api_token_secret = var.proxmox_api_token_secret         # API Token secret from variables
  pm_tls_insecure   = true                                  # Disable TLS verification (use with caution)
}

# Define the bpg-proxmox provider with its connection parameters
provider "bpg-proxmox" {
  endpoint   = "${var.proxmox_url}/api2/json"               # API endpoint for bpg-proxmox provider
  api_token  = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"  # Concatenated API token credentials
  insecure   = true                                         # Disable TLS verification
}

# Module for the Ansible VM
module "ansible" {
  # Source location for the ansible module
  source           = "./modules/ansible"

  # VM settings and network configuration passed as variables
  vm_name          = var.ansible_vm_name
  vm_id            = var.ansible_vm_id
  proxmox_node     = var.ansible_proxmox_node
  cores            = var.ansible_vm_cores
  memory           = var.ansible_vm_memory
  ip               = var.ansible_vm_ip
  subnet_cidr      = var.ansible_vm_subnet_cidr
  gateway          = var.ansible_vm_gateway
  network_config_typ_lan = var.ansible_vm_network_config_typ_lan

  # SSH keys: primary key from the file and additional SSH keys
  ssh_keys         = concat([file("~/.ssh/id_rsa.pub")], var.additional_ssh_keys)

  # RegEx filter for verifying the IP address connection
  ip_regex         = var.ansible_ip_address_filter_for_connection
  proxmox_url      = var.proxmox_url   # Pass the proxmox URL variable to the module
}

# Module for the OPNsense VM
module "OPNsense" {
  source       = "./modules/OPNsense"           # Source path for the OPNsense module

  # Basic VM details
  vm_name      = var.opnsense_vm_name
  vm_id        = var.opnsense_vm_id
  proxmox_node = var.opnsense_proxmox_node
  cores        = var.opnsense_cores
  memory       = var.opnsense_memory

  # Network bridge settings for WAN and LAN interfaces
  proxmox_ve_network_bridge_wan = var.opnsense_proxmox_ve_network_bridge_wan
  proxmox_ve_network_bridge_lan = var.opnsense_proxmox_ve_network_bridge_lan

  # VM network interface names for WAN and LAN
  vm_network_interface_wan = var.opnsense_vm_network_interface_wan
  vm_network_interface_lan = var.opnsense_vm_network_interface_lan

  # IP settings for the OPNsense VM and proxmox node
  vm_lan_ip     = var.opnsense_vm_lan_ip
  vm_wan_ip     = var.opnsense_vm_wan_ip
  wan_gateway   = var.opnsense_vm_wan_gateway
  proxmox_lan_ip = var.proxmox_lan_ip

  # DNS server configuration for the OPNsense VM
  vm_dns_server = var.opnsense_vm_dns_server

  # SSH keys: combining public SSH key from the Ansible module and local public key file
  ssh_keys = concat([module.ansible.public_ssh_key], [file("~/.ssh/id_rsa.pub")])
  
  # Passing Ansible connection configuration to OPNsense
  ansible_ip     = var.ansible_vm_ip
  ansible_ssh_key = module.ansible.public_ssh_key

  # DHCP DNS server configuration for the bind9 module dependency
  dhcp_dns_server = var.bind9_vm_ip
}

# Module for the Bind9 VM
module "bind9" {
  depends_on = [module.OPNsense]  # Ensure OPNsense module is created before Bind9

  source       = "./modules/bind9"      # Source path for the bind9 module

  # VM details and resource allocation
  vm_name      = var.bind9_vm_name
  vm_id        = var.bind9_vm_id
  proxmox_node = var.bind9_proxmox_node
  cores        = var.bind9_vm_cores
  memory       = var.bind9_vm_memory

  # SSH keys: using the public key from the Ansible module with additional SSH keys if any
  ssh_keys     = concat([module.ansible.public_ssh_key], var.additional_ssh_keys)

  # IP address configuration expressed in CIDR notation
  ip           = "${var.bind9_vm_ip}/${var.bind9_vm_subnet_cidr}"
  dns_forwarder = var.bind9_dns_forwarder
  dns_zone_net_adress = var.bind9_dns_zone_net_adress
gateway      = var.bind9_vm_gateway

  # Configuration passed to reach the ansible module and set up communication
  ansible_ip     = var.ansible_vm_ip
  ansible_ssh_key = module.ansible.public_ssh_key

  # OPNsense details to link the modules together
  opnsense_ip    = var.opnsense_vm_lan_ip
  opnsense_vm_name = var.opnsense_vm_name
}

# Module for the Nginx Webserver VM
module "nginx-webserver" {
  depends_on = [module.bind9, module.OPNsense]  # Dependencies to ensure proper creation order

  source       = "./modules/nginx-webserver"   # Source location for the Nginx module

  # Basic VM details
  vm_name      = var.nginx-webserver_vm_name
  vm_id        = var.nginx-webserver_vm_id
  proxmox_node = var.nginx-webserver_proxmox_node
  cores        = var.nginx-webserver_vm_cores
  memory       = var.nginx-webserver_vm_memory

  # SSH keys from the Ansible module concatenated with any additional keys
  ssh_keys     = concat([module.ansible.public_ssh_key], var.additional_ssh_keys)

  # Ansible connection configuration for further automation
  ansible_ip     = var.ansible_vm_ip
  ansible_ssh_key = module.ansible.public_ssh_key

  # OPNsense details such as API credentials for firewall or NAT configurations
  opnsense_vm_name  = var.opnsense_vm_name
  opnsense_api_key  = module.OPNsense.opnsense_api_key
  opnsense_api_secret = module.OPNsense.opnsense_api_secret

  # External port mapping for accessing the webserver
  external_port   = var.nginx-webserver_external_port
}

# Module for the Fileserver VM
module "fileserver" {
  depends_on = [module.bind9, module.OPNsense]  # Ensure both Bind9 and OPNsense modules are deployed first

  source       = "./modules/fileserver"   # Source location for the fileserver module

  # Basic VM configuration details
  vm_name      = var.fileserver_vm_name
  vm_id        = var.fileserver_vm_id
  proxmox_node = var.fileserver_proxmox_node
  cores        = var.fileserver_vm_cores
  memory       = var.fileserver_vm_memory

  # SSH keys combining the Ansible module public key with additional keys if provided
  ssh_keys     = concat([module.ansible.public_ssh_key], var.additional_ssh_keys)

  # Ansible connection details used for post-deployment configuration
  ansible_ip     = var.ansible_vm_ip
  ansible_ssh_key = module.ansible.public_ssh_key
}

# Module for the Docker Swarm VM
module "docker-swarm" {
  depends_on = [module.bind9, module.OPNsense]  # Ensure dependencies are created prior

  source = "./modules/docker-swarm"    # Source path for the docker-swarm module

  # Create a map of Docker Swarm Manager and Worker VMs using merge and for expressions
  # This allows dynamic generation of multiple VMs from variable counts
  docker_vms = merge(
    tomap({for i in range(var.number_docker_swarm_manager_nodes) : "docker-swarm-manager-${i+1}" => {
      vm_id         = var.docker-swarm_start_vm_id + i
      ip            = "dhcp"  # Use DHCP assignment for IP
      gateway       = ""
      proxmox_node  = var.docker-swarm_proxmox_node
      cores         = var.docker-swarm_vm_cores
      memory        = var.docker-swarm_vm_memory
      network_bridge = "vmbr1"  # Specify network bridge for containers
      ssh_keys      = concat([module.ansible.public_ssh_key], var.additional_ssh_keys)
      tags          = ["swarm","swarm-manager"]
    }}),
    tomap({for i in range(var.number_docker_swarm_worker_nodes) : "docker-swarm-worker-${i+1}" => {
      vm_id         = var.docker-swarm_start_vm_id + var.number_docker_swarm_manager_nodes + i
      ip            = "dhcp"  # Dynamically assigned IP address
      gateway       = ""
      proxmox_node  = var.docker-swarm_proxmox_node
      cores         = var.docker-swarm_vm_cores
      memory        = var.docker-swarm_vm_memory
      network_bridge = "vmbr1"
      ssh_keys      = concat([module.ansible.public_ssh_key], var.additional_ssh_keys)
      tags          = ["swarm","swarm-worker"]
    }})
  )

  # Ansible connection details shared across the swarm VMs
  ansible_ip     = var.ansible_vm_ip
  ansible_ssh_key = module.ansible.public_ssh_key

  # OPNsense information for API based configurations (e.g. firewall settings)
  opnsense_vm_name  = var.opnsense_vm_name
  opnsense_api_key  = module.OPNsense.opnsense_api_key
  opnsense_api_secret = module.OPNsense.opnsense_api_secret

  # External port mapping for Docker Swarm management dashboard or services
  external_port   = var.docker-swarm_external_port

  # Fileserver credentials to be used by Nextcloud/or SMB share integration
  smb_nextcloud_user     = module.fileserver.smb_nextcloud_user
  smb_nextcloud_password = module.fileserver.smb_nextcloud_password
}

# Module for the Nextcloud container
module "nextcloud" {
  depends_on = [module.bind9, module.OPNsense, module.fileserver, module.docker-swarm]  # Ensure all dependencies are available

  source = "./modules/nextcloud"  # Source path for the nextcloud module

  # Ansible connection details to configure Nextcloud automatically
  ansible_ip = var.ansible_vm_ip

  # Credentials for connecting to the fileserver SMB share
  smb_nextcloud_user     = module.fileserver.smb_nextcloud_user
  smb_nextcloud_password = module.fileserver.smb_nextcloud_password

  # Fileserver VM name to allow Nextcloud to reference the storage server
  fileserver_vm_name = var.fileserver_vm_name
}