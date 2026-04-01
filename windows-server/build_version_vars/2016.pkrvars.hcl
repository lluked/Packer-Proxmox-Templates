
# --- server_version ---
server_version = "2016"

# --- proxmox_os_type ---
proxmox_os_type = "win10"

# --- iso_map ---
iso_map = {
  # https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2016
  Server = {
    iso_url      = "https://software-static.download.prss.microsoft.com/pr/download/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO"
    iso_checksum = "sha256:1CE702A578A3CB1AC3D14873980838590F06D5B7101C5DAACCBAC9D73F1FB50F"
  }
  # https://www.microsoft.com/en-gb/evalcenter/download-windows-server-2016-essentials
  Server-Essentials = {
    iso_url      = "https://download.microsoft.com/download/6/9/5/6957BB28-1FAD-4E62-B161-F873196130BD/14393.0.161119-1705.RS1_REFRESH_SERVERESSENTIALS_OEM_X64FRE_EN-US.ISO"
    iso_checksum = "sha256:968222F3EF41F7390BC2825A721C97C653B627023EBD051EC1CEBCE1F9B2D250"
  }
}

# --- product_key_list ---
product_key_list = {
  Standard   = ""
  Datacenter = ""
  Essentials = "JCKRF-N37P4-C2D82-9YXRT-4M63B" # https://learn.microsoft.com/en-us/windows-server/get-started/kms-client-activation-keys?tabs=windows1110ltsc%2Cwindows81%2Cserver2025%2Cversion1803
}

# --- edition_build_map ---
edition_build_map = {
  Standard-Core  = {
    iso           = "Server"
    image_index   = 1
    product_key   = "Standard"
    default_vm_id = "1161"
  }
  Standard = {
    iso           = "Server"
    image_index   = 2
    product_key   = "Standard"
    default_vm_id = "1162"
  }
  Datacenter-Core = {
    iso           = "Server"
    image_index   = 3
    product_key   = "Datacenter"
    default_vm_id = "1163"
  }
  Datacenter = {
    iso           = "Server"
    image_index   = 4
    product_key   = "Datacenter"
    default_vm_id = "1164"
  }
  Essentials = {
    iso           = "Server-Essentials"
    image_index   = 1
    product_key   = "Essentials"
    default_vm_id = "1165"
  }
}
