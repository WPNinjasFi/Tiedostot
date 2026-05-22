#Scripti on kokonaisuudessaan Clauden tekemä
#Requires -RunAsAdministrator

$mapUrl  = 'https://raw.githubusercontent.com/microsoft/secureboot_objects/main/PostSignedObjects/KEK/kek_update_map.json'
$mapFile = Join-Path $env:TEMP 'kek_update_map.json'

$pk = Get-SecureBootUEFI -Name PK
$bytes = $pk.Bytes

# Parse EFI_SIGNATURE_LIST header: 16B GUID + 4B ListSize + 4B HdrSize + 4B SigSize
$hdrSize = [BitConverter]::ToUInt32($bytes, 20)
$sigSize = [BitConverter]::ToUInt32($bytes, 24)

# Skip list header (28) + signature header + 16B SignatureOwner GUID
$certStart = 28 + $hdrSize + 16
$certLen   = $sigSize - 16

# Strongly-typed byte[] required so the cert constructor picks the byte[] overload
$certBytes = New-Object byte[] $certLen
[Array]::Copy($bytes, $certStart, $certBytes, 0, $certLen)

$cert  = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 (,$certBytes)
$thumb = $cert.Thumbprint.ToLower()

Write-Host "PK Subject     : $($cert.Subject)"
Write-Host "PK Issuer      : $($cert.Issuer)"
Write-Host "PK Serial      : $($cert.SerialNumber.ToLower())"
Write-Host "PK Thumbprint  : $thumb"
Write-Host ""

# Use curl.exe to bypass PowerShell network restrictions
& curl.exe -sSL -o $mapFile $mapUrl
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $mapFile)) {
    Write-Error "curl.exe failed to download $mapUrl (exit $LASTEXITCODE)"
    return
}

$map = Get-Content -Raw -LiteralPath $mapFile | ConvertFrom-Json

if ($map.PSObject.Properties.Name -contains $thumb) {
    $entry = $map.$thumb
    Write-Host "MATCH found in kek_update_map.json" -ForegroundColor Green
    Write-Host "Vendor    : $(($entry.KEKUpdate -split '/')[0])"
    Write-Host "KEKUpdate : $($entry.KEKUpdate)"
    Write-Host "IssuedTo  : $($entry.Certificate.issued_to)"
    Write-Host "IssuedBy  : $($entry.Certificate.issued_by)"
    Write-Host "Serial    : $($entry.Certificate.serial_number)"
} else {
    Write-Warning "PK thumbprint $thumb NOT present in kek_update_map.json"
}