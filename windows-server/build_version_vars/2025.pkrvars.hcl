
# --- server_version ---
server_version = "2025"

# --- proxmox_os_type ---
proxmox_os_type = "win11"

# --- iso_map ---
iso_map = {
  # https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2025
  Server = {
    iso_url = "https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
    iso_checksum = "sha256:7B052573BA7894C9924E3E87BA732CCD354D18CB75A883EFA9B900EA125BFD51"
  }
}

# --- product_key_list ---
product_key_list = {
  Standard   = "" 
  Datacenter = ""
}

# --- edition_build_map ---
edition_build_map = {
  Standard-Core = {
    iso           = "Server"
    image_index   = 1
    product_key   = "Standard"
    default_vm_id = "1251"
  }

  Standard = {
    iso           = "Server"
    image_index   = 2
    product_key   = "Standard"
    default_vm_id = "1252"
  }

  Datacenter-Core = {
    iso           = "Server"
    image_index   = 3
    product_key   = "Datacenter"
    default_vm_id = "1253"
  }

  Datacenter = {
    iso           = "Server"
    image_index   = 4
    product_key   = "Datacenter"
    default_vm_id = "1254"
  }
}
