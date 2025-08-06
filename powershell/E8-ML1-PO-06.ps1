#E8-ML1-PO-06.ps1
# Imports
. (Join-Path $PSScriptRoot 'E8-config.ps1')
Import-Module (Join-Path $PSScriptRoot 'E8-Defender_auth.psm1')
Import-Module (Join-Path $PSScriptRoot 'E8-Common.psm1')

# Resolve sibling dirs
$paths = Get-E8Paths -ScriptRoot $PSScriptRoot
$kqlPath = Join-Path $paths.KqlDir 'E8-ML1-PO-06_query.kql'
$templatePath = Join-Path $paths.MsgDir 'E8-ML1-PO-06_message.html'
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

# — REPORT BUILD & SEND ———————————————————————————————
if ($result.Results.Count) {

    $htmlTable = $result.Results |
        # collapse the array to a CSV string
        Select-Object DeviceName,
                      OSPlatform,
                      VulnCount,
                      @{Name = 'CVE_List'; Expression = { ($_.VulnList) -join ', ' }} |
        ConvertTo-Html -Fragment |
        Out-String
}
else {
    $htmlTable = "<p>No vulnerabilities older than 14 days on internet-facing devices.</p>"
}

# read template and inject the table
$template     = Get-Content -Raw -Path $templatePath

$stamp   = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template -replace '<!--REPORT_TABLE-->',$htmlTable -replace '<!--STAMP-->',$stamp


# Send the email - @@@ in subject, used to enable email command in Manage Engine Service Desk Plus

$subject = "E8-ML1-PO-06 Patch Operating Systems - $stamp @@@"

Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp