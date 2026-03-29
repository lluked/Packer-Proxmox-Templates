
variable iso_map {
  type = map(object({
    iso_url      = string
    iso_checksum = string
  }))

  default = {
    # https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2016
    Server = {
      iso_url      = "https://software-static.download.prss.microsoft.com/pr/download/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
      iso_checksum = "sha256:1CE702A578A3CB1AC3D14873980838590F06D5B7101C5DAACCBAC9D73F1FB50F"
    }
    # https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2016-essentials
    Server-Essentials = {
      iso_url      = "https://download.microsoft.com/download/6/9/5/6957BB28-1FAD-4E62-B161-F873196130BD/14393.0.161119-1705.RS1_REFRESH_SERVERESSENTIALS_OEM_X64FRE_EN-US.ISO"
      iso_checksum = "sha256:968222F3EF41F7390BC2825A721C97C653B627023EBD051EC1CEBCE1F9B2D250"
    }
  }
}

variable "virtio_drivers_iso" {
  type = object({
    file     = string
    checksum = string
  })

  default = {
    file     = "virtio-win-0.1.285-1.iso"
    checksum = "sha256:E14CF2B94492C3E925F0070BA7FDFEDEB2048C91EEA9C5A5AFB30232A3976331"
  }
}

variable "edition_build_map" {
  type = map(object({
    iso          = string
    image_index  = number
    product_key  = string
    vm_id        = string
  }))

  default = {
    Standard-Core = {
      iso          = "Server"
      image_index  = 1
      product_key  = "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1161"
    }
    Standard = {
      iso          = "Server"
      image_index  = 2
      product_key  = "WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1162"
    }
    Datacenter-Core = {
      iso          = "Server"
      image_index  = 3
      product_key  = "CB7KF-BWN84-R7R2Y-793K2-8XDDG" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1163"
    }
    Datacenter = {
      iso          = "Server"
      image_index  = 4
      product_key  = "CB7KF-BWN84-R7R2Y-793K2-8XDDG" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1164"
    }
    Essentials = {
      iso          = "Server-Essentials"
      image_index  = 1
      product_key  = "JCKRF-N37P4-C2D82-9YXRT-4M63B" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1165"
    }
  }
}

variable "build_edition" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Standard-Core", "Standard", "Datacenter-Core", "Datacenter", "Essentials"], var.build_edition)
    error_message = "Must be either 'Standard-Core', 'Standard', 'Datacenter-Core', 'Datacenter', or 'Essentials'."
  }
}

variable "build_locale" {
  type    = string
  default = "en-GB"
  validation {
    condition     = contains(["en-GB", "en-US"], var.build_locale)
    error_message = "Must be either 'en-GB' or 'en-US'."
  }
}

variable "build_timezone" {
  type    = string
  default = "GMT Standard Time"
  validation {
    condition     = contains(["GMT Standard Time", "Pacific Standard Time", "UTC"], var.build_timezone)
    error_message = "Must be either 'GMT Standard Time', 'Pacific Standard Time', or 'UTC'."
  }
}

variable "build_organization" {
  type    = string
  default = "Packer Proxmox Builds"
}

variable "build_protect_your_pc" {
  type    = string
  default = "3"
  description = <<EOT
Specifies Windows Update settings:
1: Important and recommended updates are installed automatically.
2: Only important updates are installed.
3: Automatic protection is disabled. Updates are available manually through Windows Update.
EOT
  validation {
    condition     = contains(["1","2","3"], var.build_protect_your_pc)
    error_message = "Invalid value for build_protect_your_pc. Allowed values are: 1, 2, or 3."
  }
}

variable "build_admin_password" {
  type    = string
  default = "proxmox"
}

variable "build_user" {
  type    = string
  default = "proxmox"
}

variable "build_user_password" {
  type    = string
  default = "proxmox"
}

variable "build_first_logon_commands_platform" {
  type = map(list(object({
    description  = string
    command_line = string
  })))
  default = {
    proxmox = [
      {
        description  = "Install VirtIO Drivers"
        command_line = "msiexec /i F:\\virtio-win-gt-x64.msi /qn"
      },
      {
        description  = "Install VirtIO Win Guest Tools"
        command_line = "F:\\virtio-win-guest-tools.exe /quiet /norestart"
      }
    ]
  }

}

variable "build_first_logon_commands_shared" {
  type = list(object({
    description  = string
    command_line = string
  }))
  default = [
    {
      description  = "Basic Setup"
      command_line = "powershell -NoProfile -ExecutionPolicy Bypass E:\\basic-setup.ps1"
    },
    {
      description  = "WinRM Setup"
      command_line = "powershell -NoProfile -ExecutionPolicy Bypass E:\\winrm-setup.ps1"
    }
  ]
}

variable "vm_cpus" {
  type    = string
  default = "2"
}

variable "vm_memory" {
  type    = string
  default = "8192"
}

variable "vm_disk_size" {
  type    = string
  default = "120G"
}

variable "winrm_use_ssl" {
  type    = bool
  default = false
}

variable "winrm_insecure" {
  type    = bool
  default = false
}

variable "winrm_timeout" {
  type    = string
  default = "6h"
}

variable "headless" {
  type    = bool
  default = true
}

variable "update_windows" {
  type    = bool
  default = true
}

variable "restart_command" {
  type    = string
  default = "shutdown /r /t 10 /f /d p:4:1 /c \"Packer Restart\""
}
