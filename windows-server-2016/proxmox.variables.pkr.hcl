
variable "proxmox_url" {
  type    = string
  default = "https://(fqdn|ip):8006/api2/json"
}

variable "proxmox_node" {
  type    = string
  default = "node_name"
}

variable "proxmox_username" {
  type    = string
  default = "user@realm!token_name"
}

variable "proxmox_token" {
  type      = string
  default   = "token_value"
  sensitive = true
}

variable "proxmox_skip_tls_verify" {
  type    = bool
  default = true
}

variable "proxmox_iso_storage_pool" {
  type    = string
  default = "local"
}

variable "proxmox_vm_storage_pool" {
  type    = string
  default = "local"
}

variable "proxmox_bridge_adapter" {
  type    = string
  default = "vmbr0"
}
