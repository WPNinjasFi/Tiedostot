Connect-MgGraph -Scopes "DeviceManagementManagedDevices.PrivilegedOperations.All", "Group.ReadWrite.All", "DeviceManagementApps.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementRBAC.ReadWrite.All", "Directory.Read.All"


### Sync Devices
$Devices = @()
$Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"

do {
    $Result = Invoke-MgGraphRequest -Uri $Uri -Method Get -OutputType Json | ConvertFrom-Json
    $Devices += $Result.value | Where-Object OperatingSystem -eq "Windows" | Select-Object Id, deviceName
    $Uri = $Result.'@odata.nextLink'
} while ($Uri)

foreach ($Device in $Devices) {
    try {
        $Result = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($Device.id)/syncDevice" -Method Post -ContentType 'application/json'
        Write-Host "Success for" $Device.deviceName -Fore Green
    }
    catch {
        Write-Host "Fail for" $Device.deviceName -Fore Red
    }
}

### Release all Autopilot devices 
try {
    $allDevices = @()
    $uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities"

    while ($uri) {
        $Result = Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType Json
        $json = $Result | ConvertFrom-Json

        $allDevices += $json.value | Where-Object userlessEnrollmentStatus -NE "allowed"
        $uri = $json.'@odata.nextLink'
    }

    $Devices = $allDevices
} catch {
    Write-Output "error gathering devices"
}

foreach ($allDevice in $allDevices) {
    try {
        $Result = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$($allDevice.id)/allowNextEnrollment" -Headers $Headers -Method Post -ContentType 'application/json'
        Write-Output "Successfully unblocked $($allDevice.id)"
    }
    catch {
        Write-Output "Error unlocking $($allDevice.id)"
    }
}

### Rotate Bitlockers
$Devices = @()
$Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"

do {
    $Result = Invoke-MgGraphRequest -Uri $Uri -Method Get -OutputType Json | ConvertFrom-Json
    $Devices += $Result.value | Where-Object OperatingSystem -eq "Windows" | Select-Object Id, deviceName
    $Uri = $Result.'@odata.nextLink'
} while ($Uri)

foreach ($Device in $Devices) {
    try {
        $Result = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($Device.id)/rotateBitLockerKeys" -Headers $Headers -Method Post -ContentType 'application/json'
        write-host "Success for" $Device.deviceName -Fore Green
    }
    catch {
        write-host "Fail for" $Device.devicename -Fore Red
    }
}