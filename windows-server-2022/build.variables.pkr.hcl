
variable "iso_url" {
  type        = string
  description =  "https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2022"
  default     = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:3E4FA6D8507B554856FC9CA6079CC402DF11A8B79344871669F0251535255325"
}

variable "edition_build_map" {
  type = map(object({
    image_index  = number
    product_key  = string
    vm_id        = string
  }))

  default = {
    Standard-Core = {
      image_index  = 1
      product_key  = "N69G4-B89J2-4G8F4-WWYCC-J464C" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1221"
    }
    Standard = {
      image_index  = 2
      product_key  = "N69G4-B89J2-4G8F4-WWYCC-J464C" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1222"
    }
    Datacenter-Core = {
      image_index  = 3
      product_key  = "WMDGN-G9PQG-XVVXX-R3X43-63DFG" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1223"
    }
    Datacenter = {
      image_index  = 4
      product_key  = "WMDGN-G9PQG-XVVXX-R3X43-63DFG" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1224"
    }
  }
}

variable "build_edition" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Standard-Core", "Standard", "Datacenter-Core", "Datacenter"], var.build_edition)
    error_message = "Must be either 'Standard-Core', 'Standard', 'Datacenter-Core', or 'Datacenter'."
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
