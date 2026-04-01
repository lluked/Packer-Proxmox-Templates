
variable "build_edition" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Standard-Core", "Standard", "Datacenter-Core", "Datacenter", "Essentials"], var.build_edition)
    error_message = "Must be either 'Standard-Core', 'Standard', 'Datacenter-Core', 'Datacenter', or 'Essentials'."
  }
}

variable "build_vm_id" {
  type    = string
  default = ""
  description = "Optional VM ID to assign to the built image. If not specified, the default VM ID from edition_build_map will be used."
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

variable "build_first_logon_commands" {
  type = list(object({
    description  = string
    command_line = string
  }))
  default = [
    {
      description  = "Install VirtIO Drivers"
      command_line = "msiexec /i F:\\virtio-win-gt-x64.msi /qn"
    },
    {
      description  = "Install VirtIO Win Guest Tools"
      command_line = "F:\\virtio-win-guest-tools.exe /quiet /norestart"
    },
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
