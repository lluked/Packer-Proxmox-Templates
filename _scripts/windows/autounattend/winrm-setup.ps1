
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
try {
    if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder -Force | Out-Null }
} catch {
    Write-Log "Failed to create log folder '$logFolder': $($_.Exception.Message)" -Level 'ERROR'
    throw
}

Write-Log ('Logging to "{0}"' -f $logFile)
Write-Log "Starting WinRM configuration..."

# Enable WinRM
try {
    Write-Log "Running winrm quickconfig..."
    winrm quickconfig -quiet | Out-Null
    Write-Log "WinRM quickconfig completed."
} catch {
    Write-Log "Failed to enable WinRM: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
    throw
}

# Allow unencrypted traffic
try {
    Write-Log "Allowing unencrypted traffic..."
    winrm set winrm/config/service '@{AllowUnencrypted="true"}' | Out-Null
    Write-Log "Unencrypted traffic allowed."
} catch {
    Write-Log "Failed to allow unencrypted traffic: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Enable basic authentication
try {
    Write-Log "Enabling basic authentication..."
    winrm set winrm/config/service/auth '@{Basic="true"}' | Out-Null
    Write-Log "Basic authentication enabled."
} catch {
    Write-Log "Failed to enable basic authentication: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Set MaxTimeoutms
try {
    Write-Log "Setting WinRM MaxTimeoutms to 1800000..."
    winrm set winrm/config '@{MaxTimeoutms="1800000"}' | Out-Null
    Write-Log "WinRM MaxTimeoutms set successfully."
} catch {
    Write-Log "Failed to set WinRM MaxTimeoutms: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Set MaxMemoryPerShellMB
try {
    Write-Log "Setting WinRS MaxMemoryPerShellMB to 1024..."
    winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="1024"}' | Out-Null
    Write-Log "WinRS MaxMemoryPerShellMB set successfully."
} catch {
    Write-Log "Failed to set WinRS MaxMemoryPerShellMB: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Set service to automatic
try {
    Write-Log "Setting WinRM service to automatic..."
    Set-Service WinRM -StartupType Automatic
    Write-Log "WinRM service set to automatic."
} catch {
    Write-Log "Failed to set WinRM service startup type: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

# Configure firewall
try {
    Write-Log "Adding WinRM firewall rule..."
    netsh advfirewall firewall add rule name="WinRM HTTP" `
        dir=in action=allow protocol=TCP localport=5985 | Out-Null
    Write-Log "Firewall rule added."
} catch {
    Write-Log "Failed to add WinRM firewall rule: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
}

Write-Log "WinRM configuration completed successfully."
