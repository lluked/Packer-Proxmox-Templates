packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "centos-stream-9" {
  # Proxmox connection
  proxmox_url              = var.proxmox_url
  node                     = var.proxmox_node
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify

  # Proxmox
  vm_name              = var.vm_name
  vm_id                = "2001"
  template_name        = var.vm_name
  tags                 = "CentOS;CentOS-Stream;CentOS-Stream-9;RHEL"
  template_description = "CentOS Stream 9, Built ${timestamp()}"

  # Host
  os              = "l26"
  cpu_type        = "host"
  cores           = var.vm_cpus
  sockets         = 1
  memory          = var.vm_memory
  scsi_controller = "virtio-scsi-pci"

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
    iso_file     = "${var.proxmox_iso_storage_pool}:iso/${split("/", var.iso_url)[length(split("/", var.iso_url)) - 1]}"
    iso_checksum = var.iso_checksum
    unmount      = true
  }

  # Kickstart
  additional_iso_files {
    type             = "sata"
    index            = 1
    iso_storage_pool = "${var.proxmox_iso_storage_pool}"
    cd_label         = "OEMDRV"
    cd_content       = {
      "ks.cfg" = templatefile(
        "${path.root}/ks.cfg.tmpl",
        {
          hostname             = var.build_hostname
          root_password        = var.build_root_password
          user                 = var.build_user
          password             = var.build_user_password
        }
      )
    }
    unmount          = true
  }

  # Boot Command
  boot_command = [
    "<tab> inst.ks=cdrom:/ks.cfg<enter>"
  ]

  # Communicator
  communicator = "ssh"

  # SSH
  ssh_username = var.build_user
  ssh_password = var.build_user_password
  ssh_timeout  = var.ssh_timeout

  # Optional
  qemu_agent = true
}

build {
  sources = ["source.proxmox-iso.centos-stream-9"]
}
