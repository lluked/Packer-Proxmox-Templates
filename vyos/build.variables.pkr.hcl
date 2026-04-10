
variable "iso_file" {
  type        = string
  description = "The name of the VyOS ISO file to use for the build."
  default     = "vyos-1.5-rolling-202604080013-generic-amd64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "1855f3f6fbafaf3326de8cb2cd864cd6f9214747bae847f8353e9259c568386d"
}

variable "build_user" {
  type    = string
  default = "proxmox"
}

variable "build_user_password" {
  type    = string
  default = "proxmox"
}

variable "build_wait_after_bootloader" {
  type    = string
  default = "30"
}

variable "vm_cpus" {
  type    = string
  default = "1"
}

variable "vm_memory" {
  type    = string
  default = "1024"
}

variable "vm_disk_size" {
  type    = string
  default = "20G"
}
