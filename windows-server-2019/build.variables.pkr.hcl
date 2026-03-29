
variable iso_map {
  type = map(object({
    iso_url      = string
    iso_checksum = string
  }))

  default = {
    # https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2019
    Server = {
      iso_url      = "https://software-static.download.prss.microsoft.com/dbazure/988969d5-f34g-4e03-ac9d-1f9786c66749/17763.3650.221105-1748.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
      iso_checksum = "sha256:6DAE072E7F78F4CCAB74A45341DE0D6E2D45C39BE25F1F5920A2AB4F51D7BCBB"
    }
    # https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2019-essentials
    Server-Essentials = {
      iso_url      = "https://software-static.download.prss.microsoft.com/pr/download/17763.737.190906-2324.rs5_release_svc_refresh_SERVERESSENTIALS_OEM_x64FRE_en-us_1.iso"
      iso_checksum = "sha256:299F93390DD6DC3F53B332F38F5D3845E6DDE40D855286712C42F9BB97E406AC"
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
      product_key  = "N69G4-B89J2-4G8F4-WWYCC-J464C" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1191"
    }
    Standard = {
      iso          = "Server"
      image_index  = 2
      product_key  = "N69G4-B89J2-4G8F4-WWYCC-J464C" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1192"
    }
    Datacenter-Core = {
      iso          = "Server"
      image_index  = 3
      product_key  = "WMDGN-G9PQG-XVVXX-R3X43-63DFG" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1193"
    }
    Datacenter = {
      iso          = "Server"
      image_index  = 4
      product_key  = "WMDGN-G9PQG-XVVXX-R3X43-63DFG" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1194"
    }
    Essentials = {
      iso          = "Server-Essentials"
      image_index  = 1
      product_key  = "WVDHN-86M7X-466P6-VHXV7-YY726" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1195"
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
