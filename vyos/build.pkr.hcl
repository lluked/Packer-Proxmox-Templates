packer {
  required_plugins {
    proxmox = {
      version = "~> 1"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "vyos" {
  # Proxmox connection
  proxmox_url              = var.proxmox_url
  node                     = var.proxmox_node
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify

  # Proxmox
  vm_name              = "vyos"
  vm_id                = 1000
  template_name        = "vyos"
  tags                 = "VyOS"
  template_description = "VyOS , Built ${timestamp()}"

  # Host
  # os              = "win10"
  cpu_type        = "host"
  cores           = var.vm_cpus
  sockets         = 1
  memory          = var.vm_memory
  scsi_controller = "virtio-scsi-single"

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

  # Boot
  boot_iso {
    type         = "sata"
    index        = 0
    iso_file     = "${var.proxmox_iso_storage_pool}:iso/${(var.iso_file)}"
    iso_checksum = var.iso_checksum
    unmount      = true
  }
  boot_wait            = "10s"
  boot_command         = [
    # Boot Menu (Live system)
    "<enter>",
    # Wait for boot
    "<wait${var.build_wait_after_bootloader}s>",
    # Login to iso
    "vyos<enter><wait2>",
    "vyos<enter><wait2>",
    ## Start the image installation
    "install image<enter><wait2>",
    # Welcome to VyOS Installation
    # This command will install VyOS to your permanent storage.
    # Would you like to continue? [y/N]:
    "y<enter><wait2>",
    # What would you like to name this image (Default: 2025.11)
    "<enter><wait2>",
    # Please enter a password for the "vyos" user:
    "vyos<enter><wait2>",
    # Please confirm password for the "vyos" user:
    "vyos<enter><wait2>",
    # What console should be used by default? (K: KVM, S: Serial)? (Default: K)
    "<enter><wait2>",
    # Probing disks
    # 1 disk(s) found
    # The following disks were found:
    # Drive: /dev/sda (4.0GB)
    # Which one should be used for installation? (Default: /dev/sda)
    "<enter><wait2>",
    # Installation will delete all data on the drive. Continue? [y/N]
    "y<enter><wait2>",
    # No previous installation found
    # Would you like to use all the free space on the drive? [y/N]
    "y<enter><wait2>",
    # The following config files are available for boot
    #   1. /opt/vyatta/etc/config/config.boot 
    #   2. /opt/vyatta/etc/config/config.boot.default
    # Which file would you like to use as boot config? (Default: 1)
    "2<enter><wait20>",
    # Creating temporary directories
    # Mounting new partitions
    # Creating a configuration file
    # Copying system image files
    # Installing GRUB configuration files
    # Installing GRUB to the drive
    # Cleaning up
    # Unmounting target filesystems
    # Removing temporary files
    # The image installed successfully; please reboot now.
    "reboot<enter><wait2>y<enter><wait10>",
    # GRUB Boot Menu (2025.11)
    "<enter>",
    # Wait for boot
    "<wait${var.build_wait_after_bootloader}s>",
    # Login
    "vyos<enter><wait2>",
    "vyos<enter><wait2>",
    # Configure
    "configure<enter><wait2>",
    ## Setup vagrant user
    "set system login user ${var.build_user} authentication plaintext-password ${var.build_user_password}<enter><wait2>",
    "commit<enter><wait4>",
    "save<enter><wait2>",
    "exit<enter><wait2>",
    "exit<enter><wait2>",
    ## Delete vyos user
    "${var.build_user}<enter><wait2>",
    "${var.build_user_password}<enter><wait2>",
    "configure<enter><wait2>",
    "delete system login user vyos<enter><wait2>",
    ## Setup interfaces
    "delete interfaces ethernet eth0 hw-id<enter><wait2>",
    "set interfaces ethernet eth0 description \"WAN\"<enter><wait2>",
    "set interfaces ethernet eth0 address dhcp<enter><wait2>",
    ## Setup ssh
    "set service ssh port 22<enter><wait2>",
    # Save and restart
    "commit<enter><wait4>",
    "save<enter><wait2>",
    "exit<enter><wait2>",
    "reboot<enter><wait2>y<enter><wait10>",
    # GRUB Boot Menu (2025.11)
    "<enter>",
    # Wait for boot
    "<wait${var.build_wait_after_bootloader}s>",
  ]

  # SSH
  ssh_username  = var.build_user
  ssh_password  = var.build_user_password
  ssh_timeout   = "5m"
  ssh_handshake_attempts = 1000

  # Qemu Guest Agent
  qemu_agent = true
}

build {
  sources = ["source.proxmox-iso.vyos"]
}
