# Intune Remediation - Detection(/Remediate) script
# Add own custom files to be gathered with Intune Collect Diagnostics gathering
#
# Run Remediation in System context and in 64-bit PowerShell
#
# Authors:
# Petri.Paavola@yodamiitti.fi
# Microsoft MVP - Windows and Intune
#
# Panu.Saukko@protrainit.fi
# Microsoft MVP - Intune and Security Copilot


# Add your own custom file paths below
$RegPaths = @(
	"%systemroot%\System32\LogFiles\Firewall\pfirewall.log",
	"%windir%\Logs\*WPNinja*.log"
)


$RegPath = "HKLM:\SOFTWARE\Microsoft\MdmDiagnostics\Area\Autopilot\FileEntry"
$Value = 255  # 0xFF in decimal

# Ensure registry path exists
if (-not (Test-Path $RegPath)) {
	New-Item -Path $RegPath -Force | Out-Null
}

$AllSuccess = $true
$FailedRegistryKeys = ''

# Add each registry entry
foreach ($RegName in $RegPaths) {
	try {
		New-ItemProperty -Path $RegPath -Name $RegName -Value $Value -PropertyType DWord -Force | Out-Null
		$Success = $?
		if ($Success) {
			Write-Output "Registry key set: $RegName = $Value"
		} else {
			Write-Output "Failed to set registry key: $RegName = $Value"
			$FailedRegistryKeys += "$RegName; "
			$AllSuccess = $false
		}
	} catch {
		Write-Output "Fatal error with remediate script for $RegName"
		Exit 1
	}
}

if ($AllSuccess) {
	Write-Output "All registry keys set successfully"
	Exit 0
} else {
	Write-Output "Some registry keys failed to set: $FailedRegistryKeys"
	Exit 1
}
