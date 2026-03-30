packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

locals {
  vm_name = "windows-server-2019-${lower(var.build_edition)}"
  first_logon_commands = {
    for platform, cmds in var.build_first_logon_commands_platform : platform =>
    concat(cmds, var.build_first_logon_commands_shared)
  }
}

source "proxmox-iso" "windows-server-2019" {
  # Proxmox connection
  proxmox_url              = var.proxmox_url
  node                     = var.proxmox_node
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify

  # Proxmox
  vm_name              = local.vm_name
  vm_id                = var.edition_build_map[var.build_edition].vm_id
  template_name        = local.vm_name
  tags                 = "Windows;Windows-Server;Windows-Server-2019;Windows-Server-2019-${var.build_edition}"
  template_description = "Windows Server 2019 ${var.build_edition}, Built ${timestamp()}"

  # Host
  os              = "win10"
  cpu_type        = "host"
  cores           = var.vm_cpus
  sockets         = 1
  memory          = var.vm_memory
  scsi_controller = "virtio-scsi-pci"
  rng0 {
    source    = "/dev/urandom"
    max_bytes = 1024
    period    = 1000
  }

  # Network
  network_adapters {
    model  = "virtio"
    bridge = var.proxmox_bridge_adapter
  }

  # Disk
  disks {
    type         = "scsi"
    disk_size    = var.vm_disk_size
    storage_pool = var.proxmox_vm_storage_pool
    discard      = true
  }

  # Boot ISO
  boot_iso {
    type         = "sata"
    index        = 0
    iso_file     = "${var.proxmox_iso_storage_pool}:iso/${basename(var.iso_map[var.edition_build_map[var.build_edition].iso].iso_url)}"
    iso_checksum = "${var.proxmox_iso_storage_pool}:iso/${var.iso_map[var.edition_build_map[var.build_edition].iso].iso_checksum}"
    unmount      = true
  }

  # Autounattend
  additional_iso_files {
    type             = "sata"
    index            = 1
    iso_storage_pool = var.proxmox_iso_storage_pool
    cd_label         = "Setup"
    cd_content       = {
      "Autounattend.xml" = templatefile(
        "${path.root}/Autounattend.xml.tmpl",
        {
          edition              = var.build_edition
          build_locale         = var.build_locale
          image_index          = var.edition_build_map[var.build_edition].image_index
          product_key          = var.edition_build_map[var.build_edition].product_key
          organization         = var.build_organization
          timezone             = var.build_timezone
          protect_your_pc      = var.build_protect_your_pc
          admin_password       = var.build_admin_password
          user                 = var.build_user
          password             = var.build_user_password
          first_logon_commands = local.first_logon_commands["proxmox"]
        }
      )
    }
    cd_files = [
      "../_scripts/windows/autounattend/*"
    ]
    unmount          = true
  }

  # Virtio Drivers ISO
  additional_iso_files {
    type         = "sata"
    index        = 2
    iso_file     = "${var.proxmox_iso_storage_pool}:iso/${var.virtio_drivers_iso.file}"
    iso_checksum = "${var.virtio_drivers_iso.checksum}"
    unmount      = true
  }

  # Communicator
  communicator = "winrm"

  # WinRM
  winrm_username  = var.build_user
  winrm_password  = var.build_user_password
  winrm_port      = var.winrm_use_ssl ? 5986 : 5985
  winrm_use_ssl   = var.winrm_use_ssl
  winrm_insecure  = var.winrm_use_ssl ? var.winrm_insecure : null
  winrm_timeout   = var.winrm_timeout

  # Qemu Guest Agent
  qemu_agent = true
}

build {
  sources = ["source.proxmox-iso.windows-server-2019"]

  # Restart Windows
  provisioner "windows-restart" {
    restart_command = var.restart_command
    restart_timeout = "30m"
  }

  # Windows Update First Pass
  provisioner "powershell" {
    name              = "Windows Update First Pass"
    script            = "../_scripts/windows/provisioners/windows-update.ps1"
    remote_path       = "C:/Windows/Temp/Packer/provisioner_windows-update.ps1"
    elevated_user     = var.build_user
    elevated_password = var.build_user_password
    execute_command   = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File {{ .Path }}"
    environment_vars  = [
      "UPDATE_WINDOWS=${var.update_windows ? 1 : 0}"
    ]
    timeout = "2h"
  }

  # Restart Windows
  provisioner "windows-restart" {
    restart_command = var.update_windows ? var.restart_command : "echo No restart needed"
    restart_timeout = "30m"
  }

  # Windows Update Second Pass
  provisioner "powershell" {
    name              = "Windows Update Second Pass"
    script            = "../_scripts/windows/provisioners/windows-update.ps1"
    remote_path       = "C:/Windows/Temp/Packer/provisioner_windows-update.ps1"
    elevated_user     = var.build_user
    elevated_password = var.build_user_password
    execute_command   = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File {{ .Path }}"
    environment_vars  = [
      "UPDATE_WINDOWS=${var.update_windows ? 1 : 0}"
    ]
    timeout = "2h"
  }

  # Restart Windows
  provisioner "windows-restart" {
    restart_command = var.update_windows ? var.restart_command : "echo No restart needed"
    restart_timeout = "30m"
  }

  # Windows Update Third Pass
  provisioner "powershell" {
    name              = "Windows Update Third Pass"
    script            = "../_scripts/windows/provisioners/windows-update.ps1"
    remote_path       = "C:/Windows/Temp/Packer/provisioner_windows-update.ps1"
    elevated_user     = var.build_user
    elevated_password = var.build_user_password
    execute_command   = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File {{ .Path }}"
    environment_vars  = [
      "UPDATE_WINDOWS=${var.update_windows ? 1 : 0}"
    ]
    timeout = "2h"
  }

  # Restart Windows
  provisioner "windows-restart" {
    restart_command = var.update_windows ? var.restart_command : "echo No restart needed"
    restart_timeout = "30m"
  }

  # Cleanup before packaging
  provisioner "powershell" {
    name              = "Cleanup before packaging"
    script            = "../_scripts/windows/provisioners/cleanup.ps1"
    remote_path       = "C:/cleanup.ps1"
    elevated_user     = var.build_user
    elevated_password = var.build_user_password
    execute_command   = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File {{ .Path }}"
  }

}
