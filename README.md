
## 1. Projektübersicht
> Dieses Projekt orchestriert eine Proxmox Virtual Envirement bei der von VM erstellung bis hin zur Dienst installation und konfiguration alles automatisiert abläuft. Dafür werden mittels Packer Templates auf der Proxmox VE erstellt. Diese werden im Anschluss von Terraform zur VM erstellung genutzt und mittels Ansible konfiguriert.

## 2. Voraussetzungen
* Physischer oder Virtueller Server für Proxmox VE
* Physischer oder Virtueller Switch mit NAT zur Internetanbindung
* VM mit Packer und Terraform zur ausführung der Skripte


## 3. Installationsanleitung
1. Proxmox VE Templates mit Packer erstellen

    Packer Projekt initialisieren
    ```
    packer init
    ```
    Packer Templates erstellen (build) im jeweiligen Projekt Ordner
    ```
    packer build -var 'proxmox_node=<proxmox_node_name>' -var 'proxmox_vm_id=<vm_id>' -var-file=../credentials.auto.pkrvars.hcl .
    ```

2. Terraform Projekt deployn

    Terraform Projekt initialisieren
    ```
    terraform init
    ```
    Terraform Proket erstellen
    ```
    terraform apply
    ```

## 4. Architekturdiagramm

## 5. Modulreferenz