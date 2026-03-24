# Ensure PowerShell uses TLS 1.2 for web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Invoke-ZeroFreeSpace {
    param (
        [string]$Drive = "C:"
    )

    # Paths and URLs
    $sdeleteUrl = "https://download.sysinternals.com/files/SDelete.zip"
    $zipPath = "$env:TEMP\SDelete.zip"
    $extractPath = "$env:TEMP\SDelete"
    $exePath = Join-Path $extractPath "SDelete.exe"

    try {
        # Delete ZIP if it already exists
        if (Test-Path -Path $zipPath) {
            Write-Host "Deleting existing ZIP file: $zipPath"
            Remove-Item -Path $zipPath -Force
        }

        # Delete extract folder if it already exists
        if (Test-Path -Path $extractPath) {
            Write-Host "Deleting existing extraction folder: $extractPath"
            Remove-Item -Path $extractPath -Recurse -Force
        }

        # Download the zip
        Write-Host "Downloading SDelete..."
        Invoke-WebRequest -Uri $sdeleteUrl -OutFile $zipPath

        # Extract the zip
        Write-Host "Extracting SDelete..."
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)

        # Delete the Zip
        Remove-Item $zipPath -Force

        # Run sdelete to zero free space
        Write-Host "Running SDelete to zero free space on $Drive..."
        Start-Process -FilePath $exePath -ArgumentList "-z -accepteula $Drive" -Wait

    } catch {
        Write-Host "Error during SDelete operation: $($_.Exception.Message)"
    } finally {
        # Remove extracted folder after use
        if (Test-Path -Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }
    }

    Write-Host "Zero free space operation completed."
}

Write-Host "Starting pre-packaging cleanup..."

# Cleanup WinSxS component store
try {
    Write-Host "Cleaning up component store (WinSxS)..."
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet /NoRestart
    Write-Host "Component store cleanup completed successfully."
} catch {
    Write-Host "Failed to clean up component store: $($_.Exception.Message)`n$($_.Exception.StackTrace)"
}

# Delete Windows Update download cache safely
try {
    $wuDownloadPath = "C:\Windows\SoftwareDistribution\Download"

    # Stop Windows Update and BITS services
    Write-Host "Stopping Windows Update service (wuauserv) and BITS..."
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Stop-Service -Name bits -Force -ErrorAction SilentlyContinue

if ((Test-Path $wuDownloadPath -PathType Container) -and 
    (Get-ChildItem $wuDownloadPath -Force -ErrorAction SilentlyContinue | Where-Object { $_ -ne $null })) {

        Write-Host "Deleting Windows Update download cache: $wuDownloadPath"

        # Grant ownership to Administrators
        takeown /F $wuDownloadPath /R /D Y | Out-Null

        # Grant full control
        icacls $wuDownloadPath /grant Administrators:F /T | Out-Null

        # Remove hidden/system attributes before deletion
        Get-ChildItem -Path $wuDownloadPath -Recurse -Force | ForEach-Object {
            $_.Attributes = 'Normal'
        }

        # Remove all contents of the folder
        Get-ChildItem -Path $wuDownloadPath -Force | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -Recurse
            } catch {
                Write-Host "Could not delete $($_.FullName): $($_.Exception.Message)"
            }
        }

        Write-Host "Windows Update download cache deleted successfully."
    } else {
        Write-Host "No Windows Update download cache found."
    }

    # Restart Windows Update and BITS services
    Write-Host "Starting Windows Update service (wuauserv) and BITS..."
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Start-Service -Name bits -ErrorAction SilentlyContinue

} catch {
    Write-Host "Failed to delete Windows Update download cache: $($_.Exception.Message)`n$($_.Exception.StackTrace)"
}

# Delete system temporary files
try {
    $tempPath = "C:\Windows\Temp"
    if (Test-Path $tempPath) {

        # Process all folders first
        Write-Host "Deleting folders and contents in $tempPath..."
        $folders = Get-ChildItem -Path $tempPath -Directory -Force
        foreach ($folder in $folders) {
            try {
                # Grant permissions recursively
                Icacls $folder.FullName /grant Administrators:F /T
                # Delete the folder recursively
                Remove-Item -Path $folder.FullName -Recurse -Force
            } catch {
                Write-Host "Could not delete folder $($folder.FullName): $($_.Exception.Message)"
            }
        }

        # Process files directly in $tempPath
        Write-Host "Deleting files in $tempPath..."
        $files = Get-ChildItem -Path $tempPath -File -Force | Where-Object {
            $_.Name -notlike "packer-*.out*"
        }
        foreach ($file in $files) {
            try {
                # Grant permissions
                Icacls $file.FullName /grant Administrators:F
                # Delete file
                Remove-Item -Path $file.FullName -Force
            } catch {
                Write-Host "Could not delete file $($file.FullName): $($_.Exception.Message)"
            }
        }

        Write-Host "System temporary files and folders deleted successfully."
    } else {
        Write-Host "No system temporary files found."
    }
} catch {
    Write-Host "Failed to delete system temporary files: $($_.Exception.Message)`n$($_.Exception.StackTrace)"
}

# Delete user temporary folders
try {
    $userTemp = "$env:LOCALAPPDATA\Temp\*"
    if (Test-Path $userTemp) {
        Write-Host "Deleting user temporary files: $userTemp"
        Remove-Item -Path $userTemp -Recurse -Force -ErrorAction Stop
        Write-Host "User temporary files deleted successfully."
    } else {
        Write-Host "No user temporary files found."
    }
} catch {
    Write-Host "Failed to delete user temporary files: $($_.Exception.Message)"
}

# Delete thumbnail cache
try {
    $thumbCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*thumb*"
    if (Test-Path $thumbCache) {
        Write-Host "Deleting thumbnail cache: $thumbCache"
        Remove-Item -Path $thumbCache -Recurse -Force -ErrorAction Stop
        Write-Host "Thumbnail cache deleted successfully."
    } else {
        Write-Host "No thumbnail cache found."
    }
} catch {
    Write-Host "Failed to delete thumbnail cache: $($_.Exception.Message)`n$($_.Exception.StackTrace)"
}

# Shrink pagefile temporarily
try {
    Write-Host "Detecting current pagefile settings..."
    $pagefile = Get-CimInstance -ClassName Win32_PageFileSetting

    if ($pagefile) {
        Write-Host "Current pagefile found at $($pagefile.Name)"
        Write-Host "Shrinking pagefile to 512 MB temporarily..."
        
        # Shrink pagefile
        $pagefile | Set-CimInstance -Property @{InitialSize=512; MaximumSize=512}
        Write-Host "Temporary pagefile size set to 512 MB."

        # Schedule automatic restore on next boot
        $taskName = "RestorePagefileAuto"
        $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"Get-CimInstance -ClassName Win32_PageFileSetting | Set-CimInstance -Property @{InitialSize=$($pagefile.InitialSize); MaximumSize=$($pagefile.MaximumSize)}`""
        $taskTrigger = New-ScheduledTaskTrigger -AtStartup
        Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Description "Restore automatic pagefile size on next boot" -Force

        Write-Host "Scheduled task '$taskName' created to restore pagefile on next boot."
    } else {
        Write-Host "No pagefile found. Unable to modify pagefile size."
    }

} catch {
    Write-Host "Failed to shrink pagefile: $($_.Exception.Message)`n$($_.Exception.StackTrace)"
}

# Clear event logs
try {
    wevtutil el | ForEach-Object {
        try {
            $logName = $_
            if ((wevtutil gl $logName).LogMode -ne "Disabled") {
                wevtutil cl $logName
            }
        } catch {
            Write-Host "Skipped log ${logName}: $($_.Exception.Message)"
        }
    }
    Write-Host "Event logs cleared (protected logs may be skipped)."
} catch {
    Write-Host "Failed to clear event logs: $($_.Exception.Message)`n$($_.Exception.StackTrace)"
}

# Zero Free disk space
Invoke-ZeroFreeSpace

Write-Host "Pre-packaging cleanup completed."
