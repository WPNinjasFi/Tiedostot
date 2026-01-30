<#
.SYNOPSIS
    Searches Windows Event Logs for events containing a specified keyword.

.DESCRIPTION
    This script searches through enabled Windows Event Logs for events that contain a specified search term.
    It filters out certain logs and patterns to improve performance and focuses on events within a specified time window.
    Results are displayed in an interactive grid view for easy browsing and selection.

.PARAMETER SearchWord
    The keyword to search for in event messages. Default is 'update'.

.PARAMETER DaysBack
    Number of days back from current date to search for events. Default is 1.

.EXAMPLE
    .\Search_Keyword_From_Event_Logs.ps1
    
    Searches for events containing 'update' in the last 1 day using default parameters.

.EXAMPLE
    # Modify the $SearchWord variable in the script to search for different terms
    # Modify the $DaysBack variable to extend the search timeframe

.NOTES
    Author: Petri.Paavola@yodamiitti.fi
    Microsoft MVP - Windows and Intune
    Powershell.Ninja
    
    The script excludes certain high-volume logs by default for performance:
    - Security log
    - Microsoft-Windows-TaskScheduler/Operational
    - Microsoft-Windows-Security-Auditing* (wildcard)
    - *PowerShell* (wildcard)
    
    Results are displayed in Out-GridView for interactive filtering and selection.

.INPUTS
    None. The script uses hardcoded variables that can be modified within the script.

.OUTPUTS
    PSCustomObject array containing:
    - TimeCreated: Event timestamp
    - LogName: Source event log name
    - Id: Event ID
    - Level: Event level (Information, Warning, Error, etc.)
    - Provider: Event provider name
    - Message: First line of the event message
    - Event: Complete event object for further processing

.LINK
    https://github.com/WPNinjasFi/Tiedostot/tree/main/Tapahtumat/20260130%20Et%C3%A4tapaaminen

#>

   #
   #
   #
 # # #
  # #
   #

# MARK: CONFIGURATIONS

# Keyword to search. Change this!
$SearchWord = 'update'

# How many days to process
$DaysBack   = 1

   #
  # #
 # # #
   #
   #
   #


# Calculate the start time for event log search based on days back setting
$StartTime  = (Get-Date).AddDays(-$DaysBack)

# MARK: EVENT LOG EXCLUSIONS for PERFORMANCE

# 1) Exclude exact log names
# Some logs are huge and take a long time to process
$ExcludedLogs = @(
  'Security'
  'Microsoft-Windows-TaskScheduler/Operational'
)

# 2) Exclude wildcard patterns - logs that match these patterns will be skipped
$ExcludePatterns = @(
  'Microsoft-Windows-Security-Auditing*'
  '*PowerShell*'
  # Add more patterns if needed, e.g.:
  # 'Microsoft-Windows-Windows Defender*'
  # 'Microsoft-Windows-AppLocker*'
)

# MARK: GET EVENT LOG SOURCES AND APPLY FILTERS

# Get all available event logs and filter them based on our criteria
$logs = Get-WinEvent -ListLog * |
  Where-Object { $_.IsEnabled -and $_.RecordCount -gt 0 } |    # Only enabled logs with events
  Where-Object { $_.LogName -notin $ExcludedLogs } |           # Exclude specific log names
  Where-Object {                                               # Exclude wildcard patterns
    $name = $_.LogName
    -not ($ExcludePatterns | Where-Object { $name -like $_ })
  } |
  Select-Object -ExpandProperty LogName                        # Extract just the log names

# Display summary of what logs we'll process
Write-Host "Found $($logs.Count) Event logs (Excluded: $($ExcludedLogs -join ', '); Patterns: $($ExcludePatterns -join ', '))"

# MARK: SEARCH THROUGH EVENT LOGS FOR MATCHING EVENTS

$i=0
$found = foreach ($log in $logs) {
  try {
	$i++
    Write-Host "Processing log ($i/$($logs.count)): $log"

    # Performance optimization: Quick check if log has any events in our time window
    # This avoids processing logs that have no events in the specified date range
    $hasAny = Get-WinEvent -FilterHashtable @{ LogName = $log; StartTime = $StartTime } -MaxEvents 1 -ErrorAction Stop
    if (-not $hasAny) { continue }

    # Get events from the current log within our time window
    Get-WinEvent -FilterHashtable @{ LogName = $log; StartTime = $StartTime } -ErrorAction Stop |
      Where-Object { $_.Message -match [regex]::Escape($SearchWord) } |  # Filter events containing our search word
      ForEach-Object {
        # Create a custom object with relevant event information for easy viewing
        [pscustomobject]@{
          TimeCreated = $_.TimeCreated
          LogName     = $_.LogName
          Id          = $_.Id
          Level       = $_.LevelDisplayName
          Provider    = $_.ProviderName
          Message     = ($_.Message -split "`r?`n")[0]  # first line for grid view (truncated for readability)
          Event       = $_                              # raw event object preserved for further analysis
        }
      }
  }
  catch {
    # Handle errors gracefully - some logs may not be accessible or may have permission issues
    # optional: uncomment if you want to know why a log was skipped
    # Write-Host "Skipping log $log ($($_.Exception.Message))"
    continue
  }
}

# MARK: DISPLAY RESULTS IN OUT-GRIDVIEW AND ALLOW USER INTERACTION

if ($found) {
  # Show found events in interactive grid view sorted by most recent first
  # User can filter, sort, and select events from the grid
  $selected = $found | Sort-Object TimeCreated -Descending | Out-GridView -PassThru
} else {
  Write-Host "No events found containing '$SearchWord' in the last $DaysBack day(s)"
}

# If you need access to the complete event objects for further processing:
# $selectedEvents = $selected.Event
# $selectedEvents
