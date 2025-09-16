# E8-ML1-PA-07-PDF.ps1
# Imports
. (Join-Path $PSScriptRoot 'E8-config.ps1')
Import-Module (Join-Path $PSScriptRoot 'E8-Defender_auth.psm1')
Import-Module (Join-Path $PSScriptRoot 'E8-Common.psm1')

# Resolve sibling dirs
$paths = Get-E8Paths -ScriptRoot $PSScriptRoot
$kqlPath = Join-Path $paths.KqlDir 'E8-ML1-PA-07-PDF_query.kql'
$templatePath = Join-Path $paths.MsgDir 'E8-ML1-PA-07-PDF_message.html'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }
if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }

# Auth
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ApiBase $apiBase

# Load/flatten KQL
$query = Get-Content -Raw -Path $kqlPath
$query = $query -replace '(?m)^\s*//.*$','' -replace '\r?\n',' ' -replace '\s{2,}',' '
$query = $query.Trim()

# Run + render
$result = Invoke-E8Query -Query $query -Headers $headers -ApiRoot $apiBase

if ($result.Results.Count) {
    $htmlTable = $result.Results | Select-Object DeviceName, OSPlatform, LastSeen, VulnerabilityCount, ExploitAvailable, @{Name='CVEs';Expression={ ($_.CVEList -join ', ') }} | ConvertTo-Html -Fragment | Out-String
    if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
    $template = Get-Content -Path $templatePath -Raw
    #Send email
    $stamp    = (Get-Date).ToString('yyyy-MM-dd')
    $bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

    $subject = "E8-ML1-PA-07 PDF (Acrobat/Reader) Vulnerabilities older than 14d - $stamp @@@"

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = $mailFrom
    $mailTo | ForEach-Object { $mail.To.Add($_) }
    $mail.Subject = $subject
    $mail.Body = $bodyHtml
    $mail.IsBodyHtml = $true

    $smtpClient = New-Object System.Net.Mail.SmtpClient($smtp)
    $smtpClient.Send($mail)
} else {
    throw "No devices with Acrobat/Reader vulnerabilities found."
}


