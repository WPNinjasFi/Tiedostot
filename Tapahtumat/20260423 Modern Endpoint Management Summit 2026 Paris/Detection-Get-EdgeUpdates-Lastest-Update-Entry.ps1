# Intune Remediation - Detection script
# Get EdgeUpdateLog last update entry
#
# Petri.Paavola@yodamiitti.fi
# Microsoft MVP - Windows and Intune
#
# Panu.Saukko@protrainit.fi
# Microsoft MVP - Intune and Security Copilot


# EdgeUpdateLog file path
$LogFile = "C:\ProgramData\Microsoft\EdgeUpdate\Log\MicrosoftEdgeUpdate.log"

if (-not (Test-Path $LogFile)) {
    Write-Output "Log file not found"
    exit 1
}

# Read log lines, from bottom to top
$Lines = Get-Content -Path $LogFile -ErrorAction Stop #| Select-Object -Last 10000  # limit for performance
$Lines = [System.Collections.ArrayList]($Lines)
$Lines.Reverse()

$InstallerLine   = $null
$ResultLine      = $null

foreach ($line in $Lines) {
    if (-not $ResultLine -and $line -match '\[InstallerResult\]') {
        $ResultLine = $line
    }
    elseif (-not $InstallerLine -and $line -match '\[Running installer\]') {
        $InstallerLine = $line
    }

    if ($InstallerLine -and $ResultLine) { break }
}

if (-not $InstallerLine -or -not $ResultLine) {
    Write-Output "Could not find both installer and result lines"
    exit 0
}

# --- Parse Running installer line ---
# Example:
# [04/08/26 10:17:17.486][MicrosoftEdgeUpdate:msedgeupdate][44560:14560][Running installer][C:\Program Files (x86)\Microsoft\EdgeUpdate\Install\{FC620E50-ACC1-4BFF-B324-288E6767B4FA}\MicrosoftEdge_ARM64_146.0.3856.109_146.0.3856.97.exe][--msedgewebview --verbose-logging --do-not-launch-msedge --system-level][{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}]
#
# Test Regex with https://regex101.com
# MicrosoftEdge_(?<Arch>X64|ARM64|X86)_(?<ToVer>[0-9\.]+)_(?<FromVer>[0-9\.]+)\.exe
#
# Result:
# [04/08/26 10:17:17.486]...[Running installer][C:\...\MicrosoftEdge_X64_146.0.3856.109_146.0.3856.97.exe]...

$DateTime = ($InstallerLine -split '\]')[0].TrimStart('[')

# Matches only for x64 installer, adjust if needed
#$ExeMatch = [regex]::Match($InstallerLine, 'MicrosoftEdge_X64_(?<ToVer>[0-9\.]+)_(?<FromVer>[0-9\.]+)\.exe')

# Matches also ARM64, x64 and x86 installers, if needed
$ExeMatch = [regex]::Match($InstallerLine, 'MicrosoftEdge_(?<Arch>X64|ARM64|X86)_(?<ToVer>[0-9\.]+)_(?<FromVer>[0-9\.]+)\.exe')

$ToVersion   = $ExeMatch.Groups['ToVer'].Value
$FromVersion = $ExeMatch.Groups['FromVer'].Value
$Architecture = $ExeMatch.Groups['Arch'].Value

# --- Parse InstallerResult line ---
# Example:
# [04/08/26 10:18:12.232][MicrosoftEdgeUpdate:msedgeupdate][44560:14560][InstallerResult][{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}][0]
#
# Test Regex with https://regex101.com
# \[(\d+)\]$
#
# [04/08/26 10:18:12.232]...[InstallerResult]...[0]

$ExitCodeMatch = [regex]::Match($ResultLine, '\[(\d+)\]$')
$ExitCode = $ExitCodeMatch.Groups[1].Value

# --- Output final line ---
$Output = "DateTime $DateTime, EdgeUpdate ($Architecture), FromVersion $FromVersion, ToVersion $ToVersion, ExitCode $ExitCode"
Write-Output $Output

# Compliant/non-compliant logic: exit 0 always since it's just reporting
exit 0
