# Get logfiles, compress and upload to Azure Blob Storage
#
# Panu.Saukko@protrainit.fi
# Microsoft MVP - Intune and Security Copilot
# 22.9.2025


$hostname=$env:COMPUTERNAME
$timestamp= Get-Date -Format 'yyyyMMdd-HHmm'
$compressedFile="C:\windows\temp\$hostname-$timestamp-update-logs.zip"
$sessions="c:\windows\servicing\sessions\sessions.xml"
$cbs="c:\windows\logs\cbs\*.*"
Compress-Archive -Path $cbs,$sessions -DestinationPath $compressedFile -force

#Get the File-Name without path
$filename=(Get-Item $compressedfile).Name

# The target URL wit SAS Token
# 'YourOwnDirectory' in this example is custom created folder
# FIX below url to your Azure Blob
$uri ="https://YourCustomDemologfiles.blob.core.windows.net/YourOwnDirectory/$($filename)?sv=2021-10-04&st=2025-09-03T07%3A29%3A21Z&se=2026-05-31T07%3A29%3A00Z&sr=FIXME"

#Define required Headers
$headers = @{
    'x-ms-blob-type' = 'BlockBlob'
}

try {
    Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -InFile $compressedfile
} catch {
    write-host "Error StatusCode: " $_.Exception.Response.StatusCode.Value__ " StatusDescription: " $_.Exception.Response.StatusDescription
    exit 1
}
write-host "Upload of file: $filename completed successfully!"
# Delete the compressed file after upload
if (Test-Path $compressedFile) {
    Remove-Item -Path $compressedFile -Force
} 