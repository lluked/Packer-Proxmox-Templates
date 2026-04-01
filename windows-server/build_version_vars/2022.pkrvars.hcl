
# --- server_version ---
server_version = "2022"

# --- proxmox_os_type ---
proxmox_os_type = "win11"

# --- iso_map ---
iso_map = {
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
    default_vm_id = "1221"
  }

  Standard = {
    iso           = "Server"
    image_index   = 2
    product_key   = "Standard"
    default_vm_id = "1222"
  }

  Datacenter-Core = {
    iso           = "Server"
    image_index   = 3
    product_key   = "Datacenter"
    default_vm_id = "1223"
  }

  Datacenter = {
    iso           = "Server"
    image_index   = 4
    product_key   = "Datacenter"
    default_vm_id = "1224"
  }
}
