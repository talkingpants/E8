# E8-ML1-PA-06.ps1 — Non-critical (no exploit) <=14 days logic (adapt as needed)
# Imports
. (Join-Path $PSScriptRoot 'E8-config.ps1')
Import-Module (Join-Path $PSScriptRoot 'E8-Defender_auth.psm1')
Import-Module (Join-Path $PSScriptRoot 'E8-Common.psm1')

# Resolve sibling dirs
$paths = Get-E8Paths -ScriptRoot $PSScriptRoot
$kqlPath = Join-Path $paths.KqlDir 'E8-ML1-PA-06_query.kql'
$templatePath = Join-Path $paths.MsgDir 'E8-ML1-PA-06_message.html'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }
if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }

# Auth
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -SecretPath $secretPath -ApiBase $apiBase

# Load/flatten KQL
$query = Get-Content -Raw -Path $kqlPath
$query = $query -replace '(?m)^\s*//.*$','' -replace '\r?\n',' ' -replace '\s{2,}',' '
$query = $query.Trim()

# Run + render
$result = Invoke-E8Query -Query $query -Headers $headers -ApiRoot $apiBase

if ($result.Results.Count -gt 0) {
    $rows = $result.Results | Sort-Object OSPlatform, DeviceName
    $htmlTable = $rows |
        Select-Object DeviceName, OSPlatform, VulnCount, CriticalCount,
                      @{Name='OldestVulnDate';Expression={ $_.OldestVulnDate }},
                      @{Name='CVEs';Expression={ ($_.VulnList | Sort-Object | Select-Object -Unique) -join ', ' }} |
        ConvertTo-Html -Fragment |
        Out-String
} else {
    $htmlTable = '<p>No PA-06 findings.</p>'
}

$template = Get-Content -Raw -Path $templatePath
$stamp = Get-Date -Format 'yyyy-MM-dd'
$bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

$subject = "E8-ML1-PA-06 Internet facing vulnerability > 14d - $stamp @@@"

$mail = New-Object System.Net.Mail.MailMessage
$mail.From = $mailFrom
$mailTo | ForEach-Object { $mail.To.Add($_) }
$mail.Subject = $subject
$mail.Body = $bodyHtml
$mail.IsBodyHtml = $true

$smtpClient = New-Object System.Net.Mail.SmtpClient($smtp)
$smtpClient.Send($mail)
