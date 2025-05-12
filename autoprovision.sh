#!/bin/bash
set -e

# Optional: Variablen für Pfade
PROXMOX_NODE="proxmox-ve-host-1"
PACKER_UBUNTU_DIR="./packer-ITM/ubuntu-server-noble"
PACKER_OPNSENSE_DIR="./packer-ITM/opnsense"
TERRAFORM_DIR="./terraform-ITM"

echo "*** Starte Packer Ubuntu Build ***"
cd "$PACKER_UBUNTU_DIR"
packer init .
packer build -var "proxmox_vm_id=1000" -var "proxmox_node=$PROXMOX_NODE" .
cd ~/ITM-Projekt

echo "*** Starte Packer OPNsense Build ***"
cd "$PACKER_OPNSENSE_DIR"
packer build -var "proxmox_vm_id=1001" -var "proxmox_node=$PROXMOX_NODE" .
cd ~/ITM-Projekt

echo "*** Starte Terraform Deployment ***"
cd "$TERRAFORM_DIR"
terraform init
terraform apply

echo "*** Deployment abgeschlossen ***"