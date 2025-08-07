# E8-ML1-PA-01.ps1 — “devices that can be onboarded” report

# Config + modules
. (Join-Path $PSScriptRoot 'E8-config.ps1')
Import-Module (Join-Path $PSScriptRoot 'E8-Defender_auth.psm1')
Import-Module (Join-Path $PSScriptRoot 'E8-Common.psm1')

# Paths
$paths = Get-E8Paths -ScriptRoot $PSScriptRoot
$kqlPath = Join-Path $paths.KqlDir 'E8-ML1-PA-01_query.kql'
$templatePath = Join-Path $paths.MsgDir 'E8-ML1-PA-01_message.html'

if (-not (Test-Path $kqlPath))     { throw "Query file not found: $kqlPath" }
if (-not (Test-Path $templatePath)){ throw "Template file not found: $templatePath" }

# Auth
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -SecretPath $secretPath -ApiBase $apiBase

# KQL (strip comments + flatten)
$query = Get-Content -Raw -Path $kqlPath
$query = $query -replace '(?m)^\s*//.*$',''
$query = $query -replace '\r?\n',' '
$query = $query -replace '\s{2,}',' '
$query = $query.Trim()

# Run
$result = Invoke-E8Query -Query $query -Headers $headers -ApiRoot $apiBase

# Table
if ($result.Results.Count -gt 0) {
    $htmlTable = $result.Results |
        Select-Object DeviceName, OSPlatform, LastSeen, @{Name='IPs';Expression={ ($_.IPs -join '<br/>') }} |
        ConvertTo-Html -Fragment |
        Out-String

    $htmlTable = $htmlTable -replace '&lt;br/&gt;','<br/>'
} else {
    $htmlTable = '<p>No devices found that can be onboarded.</p>'
}

# Inject + send
$template = Get-Content -Raw -Path $templatePath
$stamp = Get-Date -Format 'yyyy-MM-dd'
$bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

$subject = "E8-ML1-PA-01 and ML1-PO-01 Onboarding Devices Report - $stamp @@@"

$mail = New-Object System.Net.Mail.MailMessage
$mail.From = $mailFrom
$mailTo | ForEach-Object { $mail.To.Add($_) }
$mail.Subject = $subject
$mail.Body = $bodyHtml
$mail.IsBodyHtml = $true

$smtpClient = New-Object System.Net.Mail.SmtpClient($smtp)
$smtpClient.Send($mail)
