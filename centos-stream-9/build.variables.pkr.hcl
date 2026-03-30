
variable "vm_name" {
  type    = string
  default = "centos-stream-9"
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
  default = "60G"
}

variable "iso_url" {
  type    = string
  default = "https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso.SHA256SUM"
}

variable "build_root_password" {
  type    = string
  default = "proxmox"
}

variable "build_hostname" {
  type    = string
  default = "CentOS-Stream-9"
}

variable "build_user" {
  type    = string
  default = "proxmox"
}

variable "build_user_password" {
  type    = string
  default = "proxmox"
}

variable "ssh_timeout" {
  type    = string
  default = "6h"
}
