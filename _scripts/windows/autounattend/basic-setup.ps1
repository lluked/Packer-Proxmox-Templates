
# Logging function
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = 'INFO'  # INFO, WARN, ERROR
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    # Output to console immediately
    [Console]::Out.WriteLine($logMessage)
    [Console]::Out.Flush()

    # Write to file immediately
    if ($script:logFile) {
        try {
            $stream = [System.IO.StreamWriter]::new($script:logFile, $true)
            $stream.WriteLine($logMessage)
            $stream.Flush()
            $stream.Close()
        } catch {
            Write-Error "Failed to write to log file '$script:logFile': $($_.Exception.Message)"
        }
    }
}

# Dynamically set log file based on script name
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$logFile = "C:\Windows\Temp\Packer\autounattend_$scriptName.log"
$logFolder = Split-Path $logFile
if (-not (Test-Path $logFolder)) {
    try {
        New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
    } catch {
        Write-Error "Failed to create log folder '$logFolder': $($_.Exception.Message)"
    }
}

Write-Log ("Logging to '{0}'" -f $logFile)
Write-Log "Starting basic setup..."

# Log current IPv4 addresses
try {
    $ipv4Addresses = Get-NetIPAddress -AddressFamily IPv4 |
                     Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } |
                     Select-Object -ExpandProperty IPAddress

    if ($ipv4Addresses) {
        foreach ($ip in $ipv4Addresses) {
            Write-Log "Current IPv4 address: $ip"
        }
    } else {
        Write-Log "No valid IPv4 address found" -Level 'WARN'
    }
} catch {
    Write-Log "Failed to get IPv4 addresses: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Disable Hibernation
try {
    Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power\ -Name HiberFileSizePercent -Value 0 -ErrorAction Stop
    Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\Power\ -Name HibernateEnabled -Value 0 -ErrorAction Stop
    Write-Log "Hibernation disabled"
} catch {
    Write-Log "Failed to disable hibernation: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Disable Sleep
try {
    powercfg /change standby-timeout-ac 0
    powercfg /change standby-timeout-dc 0
    Write-Log "Sleep disabled"
} catch {
    Write-Log "Failed to disable sleep: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Set network profiles to Private
try {
    Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction Stop
    Write-Log "Network profiles set to Private"
} catch {
    Write-Log "Failed to set network profiles: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Disable network discovery prompt window
try {
    reg add "HKLM\System\CurrentControlSet\Control\Network" /v NewNetworkWindowOff /t REG_DWORD /d 1 /f
    Write-Log "Network discovery prompt window disabled"
} catch {
    Write-Log "Failed to disable network discovery prompt: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Disable IPv6
try {
    Get-NetAdapter | ForEach-Object {
        try {
            Disable-NetAdapterBinding -InterfaceAlias $_.Name -ComponentID ms_tcpip6 -ErrorAction Stop
            Write-Log "Disabled IPv6 on adapter: $($_.Name)"
        } catch {
            Write-Log "Failed to disable IPv6 on adapter $($_.Name): $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
        }
    }
} catch {
    Write-Log "Failed to enumerate network adapters: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Disable Teredo tunneling
try {
    netsh interface teredo set state disabled
    Write-Log "Teredo IPv6 tunneling disabled"
} catch {
    Write-Log "Failed to disable Teredo tunneling: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Allow ICMP ping
try {
    netsh advfirewall firewall add rule name='ICMP Allow incoming V4 echo request' protocol=icmpv4:8,any dir=in action=allow
    Write-Log "ICMP v4 echo requests allowed through firewall"
} catch {
    Write-Log "Failed to allow ICMP echo requests: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Enable Remote UAC Access for Local Admins
try {
    reg add "HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Policies\\System" /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f
    Write-Log "Remote UAC Access enabled for Local Admins"
} catch {
    Write-Log "Failed to enable Remote UAC Access: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Disable password expiration for the build user
try {
    $currentUser = $env:USERNAME
    Set-LocalUser -Name $currentUser -PasswordNeverExpires $true -ErrorAction Stop
    Write-Log "Password expiration disabled for user '$currentUser'"
} catch {
    Write-Log "Failed to disable password expiration for user '$currentUser': $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

Write-Log "Basic setup completed"
