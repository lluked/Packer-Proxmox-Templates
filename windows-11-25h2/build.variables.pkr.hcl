
variable "edition_build_map" {
  type = map(object({
    iso_file     = string
    iso_checksum = string
    image_name   = string
    product_key  = string
    vm_id        = string
  }))

  default = {
    Pro = {
      iso_file     = "Win10_22H2_EnglishInternational_x64v1.iso"
      iso_checksum = "sha256:EDC53C5C5FE6926DEA23FC3E884FBCF78CC2B9E76364BE968F806FC6D42B59D2"
      image_name   = "Windows 10 Pro"
      product_key  = "W269N-WFGWX-YVC9B-4J6C9-T83GX" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
      vm_id        = "1101"
    }
    # https://www.microsoft.com/en-gb/evalcenter/download-windows-11-enterprise
    Enterprise = {
      iso_file     = "26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-gb.iso"
      iso_checksum = "sha256:A61ADEAB895EF5A4DB436E0A7011C92A2FF17BB0357F58B13BBC4062E535E7B9"
      image_name   = "Windows 11 Enterprise Evaluation"
      product_key  = "" # Does not need a product key as it is built into the Eval ISO.
      vm_id        = "1102"
    }
  }
}

variable "virtio_drivers_iso" {
  type = object({
    file     = string
    checksum = string
  })

  default = {
    file     = "virtio-win-0.1.229.iso"
    checksum = "sha256:C88A0DDE34605EAEE6CF889F3E2A0C2AF3CAEB91B5DF45A125CA4F701ACBBBE0"
  }
}

variable "build_edition" {
  type    = string
  default = "Enterprise"
  validation {
    condition     = contains(["Enterprise", "Pro"], var.build_edition)
    error_message = "Must be either 'Enterprise' or 'Pro'."
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

variable "vm_cpu_cores" {
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

variable "vm_secure_boot" {
  type    = bool
  default = true
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
