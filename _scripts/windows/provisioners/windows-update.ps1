
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
$logFile = "C:\Windows\Temp\Packer\provisioner_$scriptName.log"
$logFolder = Split-Path $logFile
try {
    if (-not (Test-Path $logFolder)) { New-Item -ItemType Directory -Path $logFolder -Force | Out-Null }
} catch {
    Write-Log "Failed to create log folder '$logFolder': $($_.Exception.Message)" -Level 'ERROR'
    throw
}

Write-Log ('Logging to "{0}"' -f $logFile)
Write-Log "Windows Update script started..."

# Skip update UPDATE_WINDOWS env is false
$UpdateWindows = [bool][int]$env:UPDATE_WINDOWS
Write-Log "UPDATE_WINDOWS env - value: $UpdateWindows, type: $($UpdateWindows.GetType().Name)"
if (-not $UpdateWindows) {
    Write-Log "Skipping Windows Update as per ENV Value."
    exit 0
}

# Function to disable Delivery Optimization
function Disable-DeliveryOptimization {

    # Registry path
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"

    # Hardcoded mode to disable Delivery Optimization
    $mode = 99

    # Create key if missing
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    # Get current value (if any)
    $currentMode = (Get-ItemProperty -Path $path -Name "DODownloadMode" -ErrorAction SilentlyContinue).DODownloadMode

    if ($currentMode -ne $mode) {
        # Set the new mode
        Set-ItemProperty -Path $path -Name "DODownloadMode" -Type DWord -Value $mode
        # Restart Delivery Optimization service
        Restart-Service dosvc -Force
        Write-Log "Delivery Optimization disabled and service restarted."
    }
    else {
        Write-Log "Delivery Optimization is already disabled."
    }
}

# Function to configure Delivery Optimization
function Set-DeliveryOptimization{
    param (
        [int]$Mode = 0 # Microsoft-only mode
    )

    # Registry path
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"

    # Create key if missing
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    # Track if anything changed
    $changed = $false

    # Get current value (if any)
    $currentMode = (Get-ItemProperty -Path $path -Name "DODownloadMode" -ErrorAction SilentlyContinue).DODownloadMode

    # Set Mode
    if ($currentMode -ne $Mode) {
        Set-ItemProperty -Path $path -Name "DODownloadMode" -Type DWord -Value $Mode
        Write-Log "Delivery Optimization Mode set to $Mode."
        $changed = $true
    }
    else {
        Write-Log "Delivery Optimization Mode already set to $Mode."
    }

    # Explicitly set unlimited DOWNLOAD bandwidth (0 = unlimited)
    $downloadSettings = @{
        "DOMaxDownloadBandwidth"           = 0
        "DOMaxDownloadBandwidthForeground" = 0
        "DOMaxDownloadBandwidthBackground" = 0
        "DOPercentageMaxDownloadBandwidth" = 0
    }

    foreach ($key in $downloadSettings.Keys) {

        $currentValue = (Get-ItemProperty -Path $path -Name $key -ErrorAction SilentlyContinue).$key

        if ($currentValue -ne $downloadSettings[$key]) {
            Set-ItemProperty -Path $path -Name $key -Type DWord -Value $downloadSettings[$key]
            Write-Log "Set $key to $downloadSettings[$key]."
            $changed = $true
        }
        else {
            Write-Log "$key already set to $downloadSettings[$key]."
        }
    }

    # Restart only if something changed
    if ($changed) {
        Restart-Service dosvc -Force
        Write-Log "Delivery Optimization service restarted due to configuration change."
    }
    else {
        Write-Log "No changes detected. Delivery Optimization service restart not required."
    }
}

# Function to setup PSWindowsUpdate module
function Initialize-PSWindowsUpdate {

    # Install PSWindowsUpdate module if missing
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        # Set TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Install NuGet PackageProvider if missing
        if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {

            Write-Log "Installing NuGet PackageProvider..."
            try {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -ForceBootstrap -Force -Confirm:$false -Scope CurrentUser
            } catch {
                Write-Log "Failed to install NuGet PackageProvider: $($_.Exception.Message)" "WARN"
                throw "PSWindowsUpdate Setup failed."
            }
            Write-Log "NuGet PackageProvider Installed."
        } else{
            Write-Log "NuGet PackageProvider already Installed."
        }

        # Install PSWindowsUpdate module
        Write-Log "Installing PSWindowsUpdate module..."
        try {
            Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser
        } catch {
            Write-Log "Failed to install PSWindowsUpdate module: $($_.Exception.Message)" "WARN"
            throw "PSWindowsUpdate Setup failed."
        }
        Write-Log "PSWindowsUpdate module Installed."

    } else {
        Write-Log "PSWindowsUpdate module already Installed."
    }

    # Import PSWindowsUpdate module
    Write-Log "Importing PSWindowsUpdate module..."
    try {
        Import-Module PSWindowsUpdate -ErrorAction Stop
    } catch {
        Write-Log "Failed to import PSWindowsUpdate module: $($_.Exception.Message)" "WARN"
        throw "PSWindowsUpdate Setup failed."
    }

    Write-Log "PSWindowsUpdate Initialized."

}

# Function to check if Windows Update is running and attempt to start it if not
function Confirm-WindowsUpdateServiceIsRunning {
    param (
        [int]$MaxRetries = 4,
        [int]$WaitSeconds = 60
    )

    $retryCount = 0

    while ($retryCount -lt $MaxRetries) {
        try {
            $wuService = Get-Service -Name wuauserv -ErrorAction Stop

            if ($wuService.Status -eq 'Running') {
                Write-Log "Windows Update service is running."
                break
            } else {
                Write-Log "Windows Update service is not running. Attempting to start..."
                Start-Service -Name wuauserv -ErrorAction Stop
                Write-Log "Service start command issued. Waiting $WaitSeconds seconds..."
                Start-Sleep -Seconds $WaitSeconds
            }
        } catch {
            Write-Log "Failed to check or start Windows Update service: $($_.Exception.Message)" -Level 'WARN'
        }

        $retryCount++
        if ($retryCount -ge $MaxRetries) {
            Write-Log "Windows Update service failed to start after $MaxRetries attempts." -Level 'ERROR'
            throw "Cannot start Windows Update service."
        }
    }
}

# Function to check if windows update worker is active (TiWorker running)
function Check-WindowsUpdateWorkerActive {
    $tiWorker = Get-Process -Name TiWorker -ErrorAction SilentlyContinue
    if ($tiWorker) {
        Write-Log "Updates are currently being installed (TiWorker running)."
        $tiWorker | ForEach-Object { 
            Write-Log ("TiWorker process running - PID: {0}, CPU: {1} sec, Memory: {2:N2} MB, Started: {3}" -f $_.Id, $_.CPU, ($_.WorkingSet64 / 1MB), $_.StartTime) 
        }
        return $true  # Worker is active
    }
    else {
        Write-Log "Updates are not currently being installed (TiWorker not running)."
        return $false  # Worker is not active
    }
}

# Function to check if windows update is busy
function Confirm-WindowsUpdateNotBusy {
    param(
        [int]$MaxRetries = 5,
        [int]$WaitMinutes = 5
    )

    $retryCount = 0

    while ($true) {
        $update_worker_active = Check-WindowsUpdateWorkerActive

        if ($update_worker_active -eq $false) {
            Write-Log "Windows Update is not busy."
            return $true  # Windows Update is not busy
        }

        $retryCount++
        Write-Log "Windows Update is busy. Waiting $WaitMinutes minutes before retry $retryCount/$MaxRetries..." -Level 'INFO'

        if ($retryCount -ge $MaxRetries) {
            Write-Log "Windows Update still busy after $MaxRetries retries." -Level 'WARN'
            return $false  # Windows Update is busy
        }

        Start-Sleep -Seconds ($WaitMinutes * 60)
    }
}

# Function to check if Windows Update is pending reboot
function Check-WindowsUpdatePendingReboot {
    try {
        $pendingReboot = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
        if ($pendingReboot) {
            return $true
        } else {
            return $false
        }
    } catch {
        Write-Log "Failed to check pending reboot: $($_.Exception.Message)" -Level 'WARN'
        return $false
    }
}

# Disable Delivery Optimization
$osName = (Get-ComputerInfo).WindowsProductName
if ($osName -match "Server") {
    Write-Output "Server OS detected: $osName. Skipping Delivery Optimization configuration."
} else {
    Write-Output "Client OS detected: $osName. Configuring Delivery Optimization..."
    Set-DeliveryOptimization
}

# Setup PSWindowsUpdate
Initialize-PSWindowsUpdate

# Ensure service is running before checking updates
Confirm-WindowsUpdateServiceIsRunning -MaxRetries 3 -WaitSeconds 60

# Wait for Windows Update to be ready
$updateNotBusy = Confirm-WindowsUpdateNotBusy -MaxRetries 5 -WaitMinutes 3
if ($updateNotBusy -eq $false) {
    Write-Host "Windows Update was busy. Exiting script..."
    exit 0
}
Write-Host "Windows Update is ready. Continuing..."

# Check for pending reboot first and exit cleanly if detected
if (Check-WindowsUpdatePendingReboot) {
    Write-Log "Windows Update is pending reboot. Exiting script cleanly." -Level 'WARN'
    exit 0
} else {
    Write-Log "No Windows Update pending reboot detected."
}

# Check for updates and download
try {
    Write-Log "Checking for available updates..."
    $available = Get-WindowsUpdate
    if ($available) {
        Write-Log "Found $($available.Count) updates."
        # Log each available update
        $available | ForEach-Object { Write-Log "Update Available: $($_.Title) [$($_.Size)]" }
    } else {
        Write-Log "No updates available. Exiting."
        exit 0
    }
} catch {
    Write-Log "Failed to check or download updates: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
    exit 1
}

# Install updates
try {
    if ($available) {
        Write-Log "Installing updates..."
        Install-WindowsUpdate `
            -AcceptAll `
            -IgnoreReboot `
            -Confirm:$false `
            -Verbose `
            -ErrorAction SilentlyContinue
        Write-Log "Updates installation completed. Reboot may be required manually."
    }
} catch {
    Write-Log "Failed to install updates: $($_.Exception.Message)`n$($_.Exception.StackTrace)" -Level 'ERROR'
    exit 1
}

# Delay until windows update has finished
$updateNotBusy = Confirm-WindowsUpdateNotBusy -MaxRetries 10 -WaitMinutes 3
if ($updateNotBusy -eq $false) {
    Write-Host "Windows Update was busy. Exiting script..."
    exit 0
}

Write-Log "Windows Update script completed."
