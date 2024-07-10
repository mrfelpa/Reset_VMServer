
Import-Module VMware.PowerCLI

$retryAttempts = 0
do {
    try {
        Connect-VIServer -Server $vcenterServer -User $vcenterUser -Password $vcenterPassword
        break
    }
    catch {
        $retryAttempts++
        if ($retryAttempts -le $retryCount) {
            Write-Host "Failed to connect to vCenter. Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
        }
        else {
            Write-Host "Failed to connect to vCenter after $retryAttempts attempts. Exiting script."
            return
        }
    }
} while ($retryAttempts -le $retryCount)

$serverStatus = Test-Connection -ComputerName $serverIP -Count 3 -Quiet

if (-not $serverStatus) {
    Write-Host "Server is unresponsive. Resetting server in vCenter..."

    $retryAttempts = 0
    do {
        try {
            $vm = Get-VM -Name "ServerName" -Server $vcenterServer
            break
        }
        catch {
            $retryAttempts++
            if ($retryAttempts -le $retryCount) {
                Write-Host "Failed to get the virtual machine. Retrying in $retryDelay seconds..."
                Start-Sleep -Seconds $retryDelay
            }
            else {
                Write-Host "Failed to get the virtual machine after $retryAttempts attempts. Exiting script."
                return
            }
        }
    } while ($retryAttempts -le $retryCount)

    # Reset the virtual machine
    $vm | Restart-VM -Confirm:$false
    Write-Host "Server reset successfully!"
}
else {
    Write-Host "Server is responding normally."
}

# Disconnect from the vCenter
$retryAttempts = 0
do {
    try {
        Disconnect-VIServer -Confirm:$false
        break
    }
    catch {
        $retryAttempts++
        if ($retryAttempts -le $retryCount) {
            Write-Host "Failed to disconnect from vCenter. Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
        }
        else {
            Write-Host "Failed to disconnect from vCenter after $retryAttempts attempts. Exiting script."
            return
        }
    }
} while ($retryAttempts -le $retryCount)
