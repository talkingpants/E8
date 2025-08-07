# E8-ML1-PA-04-Browsers.ps1

# Imports
. (Join-Path $PSScriptRoot 'E8-config.ps1')
Import-Module (Join-Path $PSScriptRoot 'E8-Defender_auth.psm1')
Import-Module (Join-Path $PSScriptRoot 'E8-Common.psm1')

# Resolve sibling dirs
$paths = Get-E8Paths -ScriptRoot $PSScriptRoot
$kqlPath = Join-Path $paths.KqlDir 'E8-ML1-PA-04-Browser_query.kql'
$templatePath = Join-Path $paths.MsgDir 'E8-ML1-PA-04-Browser_message.html'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }
if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }

# Auth
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -SecretPath $secretPath -ApiBase $apiBase

# Load/flatten KQL
$query = Get-Content -Raw -Path $kqlPath
$query = $query -replace '(?m)^\s*//.*$','' -replace '\r?\n',' ' -replace '\s{2,}',' '
$query = $query.Trim()

# Run + render (as in your existing script body)
$result = Invoke-E8Query -Query $query -Headers $headers -ApiRoot $apiBase

# Build the HTML table
if ($result.Results.Count) {
    $htmlTable = $result.Results |
    Select-Object DeviceName, OSPlatform, VulnCount, CriticalCount, OldestVulnDate, @{Name='CVEs'; Expression = { ($_.VulnList -join ', ') }} |
    ConvertTo-Html -Fragment |
    Out-String
}
else {
    $htmlTable = "<p>No devices with Browser vulnerabilities found.</p>"
}

# Inject into the HTML template
$template = Get-Content -Path $templatePath -Raw
$stamp = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

# Send the report
$subject = "E8-ML1-PA-04 Browser Vulnerability Report - $stamp @@@"

$mail = New-Object System.Net.Mail.MailMessage
$mail.From = $mailFrom
$mailTo | ForEach-Object { $mail.To.Add($_) }
$mail.Subject = $subject
$mail.Body = $bodyHtml
$mail.IsBodyHtml = $true

$smtpClient = New-Object System.Net.Mail.SmtpClient($smtp)
$smtpClient.Send($mail)
