
Import-Module VMware.PowerCLI

$global:vcenterServer = $null
$global:vcenterUser = $null
$global:vcenterPassword = $null
$global:connected = $false
$global:logFile = "vCenterManagement.log"
$global:configFile = "vCenterConfig.json"

function Log-Message {
    param (
        [string]$message
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp - $message" | Out-File -Append -FilePath $global:logFile
}

function Load-Configuration {
    if (Test-Path $global:configFile) {
        $config = Get-Content $global:configFile | ConvertFrom-Json
        $global:vcenterServer = $config.Server
        $global:vcenterUser = $config.User
        $global:vcenterPassword = $config.Password
        Write-Host "Configuration loaded from $global:configFile" -ForegroundColor Green
    } else {
        Write-Host "No configuration file found. Please connect to vCenter." -ForegroundColor Yellow
    }
}

function Save-Configuration {
    $config = @{
        Server = $global:vcenterServer
        User = $global:vcenterUser
        Password = $global:vcenterPassword
    }
    $config | ConvertTo-Json | Set-Content $global:configFile
    Write-Host "Configuration saved to $global:configFile" -ForegroundColor Green
}

function Show-CLI_Menu {
    Clear-Host
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "   vCenter Management Tool" -ForegroundColor Cyan
    Write-Host "==============================="
    Write-Host "Status: " -NoNewline
    if ($global:connected) {
        Write-Host "Connected to $global:vcenterServer" -ForegroundColor Green
    } else {
        Write-Host "Not connected" -ForegroundColor Red
    }
    Write-Host "==============================="
    Write-Host "1. Connect to vCenter"
    Write-Host "2. Check Server Status"
    Write-Host "3. Reset Server"
    Write-Host "4. Disconnect from vCenter"
    Write-Host "5. Help"
    Write-Host "6. Exit"
    Write-Host "==============================="
}

function Connect-ToVCenter {
    param (
        [string]$vcenterServer,
        [string]$vcenterUser,
        [string]$vcenterPassword,
        [int]$retryCount = 3,
        [int]$retryDelay = 5
    )

    $retryAttempts = 0
    do {
        try {
            Connect-VIServer -Server $vcenterServer -User $vcenterUser -Password $vcenterPassword -ErrorAction Stop
            $global:connected = $true
            Write-Host "Connected to vCenter successfully!" -ForegroundColor Green
            Log-Message "Connected to vCenter: $vcenterServer"
            Save-Configuration
            return $true
        }
        catch {
            $retryAttempts++
            if ($retryAttempts -le $retryCount) {
                Write-Host "Failed to connect. Retrying in $retryDelay seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryDelay
            }
            else {
                Write-Host "Failed to connect after $retryAttempts attempts. Please check your credentials and server address." -ForegroundColor Red
                Log-Message "Failed to connect to vCenter: $vcenterServer after $retryAttempts attempts."
                return $false
            }
        }
    } while ($retryAttempts -le $retryCount)
}

function Check-ServerStatus {
    param (
        [string[]]$serverIPs
    )

    foreach ($serverIP in $serverIPs) {
        if (-not $serverIP) {
            Write-Host "Server IP cannot be empty." -ForegroundColor Red
            continue
        }

        Write-Host "Checking status of server '$serverIP'..." -ForegroundColor Cyan
        $serverStatus = Test-Connection -ComputerName $serverIP -Count 3 -Quiet
        if ($serverStatus) {
            Write-Host "Server '$serverIP' is responding normally." -ForegroundColor Green
        } else {
            Write-Host "Server '$serverIP' is unresponsive." -ForegroundColor Red
        }
    }
}

function Reset-Server {
    param (
        [string[]]$vmNames
    )

    foreach ($vmName in $vmNames) {
        if (-not $vmName) {
            Write-Host "VM Name cannot be empty." -ForegroundColor Red
            continue
        }

        $confirm = Read-Host "Are you sure you want to reset the VM '$vmName'? (Y/N)"
        if ($confirm -ne 'Y' -and $confirm -ne 'y') {
            Write-Host "Operation cancelled for '$vmName'." -ForegroundColor Yellow
            continue
        }

        $retryAttempts = 0
        $retryCount = 3
        $retryDelay = 5

        do {
            try {
                Write-Host "Resetting VM '$vmName'..." -ForegroundColor Cyan
                $vm = Get-VM -Name $vmName -Server $global:vcenterServer -ErrorAction Stop
                $vm | Restart-VM -Confirm:$false
                Write-Host "Server '$vmName' reset successfully!" -ForegroundColor Green
                Log-Message "Server '$vmName' reset successfully."
                break
            }
            catch {
                $retryAttempts++
                if ($retryAttempts -le $retryCount) {
                    Write-Host "Failed to get the virtual machine. Retrying in $retryDelay seconds..." -ForegroundColor Yellow
                    Start-Sleep -Seconds $retryDelay
                }
                else {
                    Write-Host "Failed to reset the virtual machine '$vmName' after $retryAttempts attempts." -ForegroundColor Red
                    Log-Message "Failed to reset the virtual machine '$vmName' after $retryAttempts attempts."
                }
            }
        } while ($retryAttempts -le $retryCount)
    }
}

function Show-Help {
    Clear-Host
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "   Help - vCenter Management Tool" -ForegroundColor Cyan
    Write-Host "==============================="
    Write-Host "1. Connect to vCenter: Establish a connection to the vCenter server."
    Write-Host "2. Check Server Status: Verify if specified servers are responding."
    Write-Host "3. Reset Server: Restart specified virtual machines."
    Write-Host "4. Disconnect from vCenter: Disconnect from the vCenter server."
    Write-Host "5. Help: Display this help information."
    Write-Host "6. Exit: Exit the application."
    Write-Host "==============================="
    Read-Host "Press Enter to return to the menu"
}

Load-Configuration

do {
    Show-CLI_Menu
    $choice = Read-Host "Select an option"

    switch ($choice) {
        '1' {
            if ($global:connected) {
                Write-Host "Already connected to vCenter. Please disconnect first to connect again." -ForegroundColor Yellow
                continue
            }
            $global:vcenterServer = Read-Host "Enter vCenter Server"
            $global:vcenterUser = Read-Host "Enter Username"
            $global:vcenterPassword = Read-Host "Enter Password" -AsSecureString
            $global:vcenterPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($global:vcenterPassword))
            Connect-ToVCenter -vcenterServer $global:vcenterServer -vcenterUser $global:vcenterUser -vcenterPassword $global:vcenterPasswordPlain
        }
        '2' {
            if (-not $global:connected) {
                Write-Host "You must be connected to vCenter to check server status." -ForegroundColor Red
                continue
            }
            $serverIPs = Read-Host "Enter Server IPs (comma-separated)" -Split ','
            Check-ServerStatus -serverIPs $serverIPs
        }
        '3' {
            if (-not $global:connected) {
                Write-Host "You must be connected to vCenter to reset a server." -ForegroundColor Red
                continue
            }
            $vmNames = Read-Host "Enter VM Names to Reset (comma-separated)" -Split ','
            Reset-Server -vmNames $vmNames
        }
        '4' {
            if (-not $global:connected) {
                Write-Host "You are not connected to vCenter." -ForegroundColor Red
                continue
            }
            Disconnect-VIServer -Confirm:$false
            $global:connected = $false
            Write-Host "Disconnected from vCenter." -ForegroundColor Green
            Log-Message "Disconnected from vCenter."
        }
        '5' {
            Show-Help
        }
        '6' {
            if ($global:connected) {
                Disconnect-VIServer -Confirm:$false
                Write-Host "Disconnected from vCenter." -ForegroundColor Green
            }
            Write-Host "Exiting..." -ForegroundColor Cyan
            break
        }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
        }
    }
    Write-Host ""
} while ($true)
