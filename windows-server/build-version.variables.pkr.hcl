# --- Server version ---
variable "server_version" {
  type    = string
  description = "Windows Server version to build."
}

# --- Proxmox OS type ---
variable "proxmox_os_type" {
  type    = string
  description = "Proxmox OS type for the virtual machine."
}

# --- ISO map ---
variable "iso_map" {
  type = map(object({
    iso_url      = string
    iso_checksum = string
  }))
  description = "Mapping of Windows Server editions to ISO URLs and checksums."
}

# --- Product keys ---
variable "product_key_list" {
  type = map(string)
  description = "Product keys for each Windows Server edition."
}

# --- Edition to build mapping ---
variable "edition_build_map" {
  type = map(object({
    iso           = string
    image_index   = number
    product_key   = string
    default_vm_id = string
  }))
  description = "Mapping of Windows Server editions to build parameters."
}