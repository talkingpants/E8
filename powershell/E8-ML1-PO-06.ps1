# --- CONFIG ---------------------------------------------------------------
$authPath = Join-Path $PSScriptRoot 'E8-Defender_auth.ps1'
$configPath = Join-Path $PSScriptRoot 'E8-config.ps1'

if (!(Test-Path $authPath)) { throw "Auth file not found: $authPath" }
if (!(Test-Path $configPath)) { throw "Config file not found: $configPath" }

. $configPath
. $authPath

# — TOKEN ————————————————————————————————————————————————
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ClientSecret $secret

# — KQL ————————————————————————————————————————————————
# Store the KQL query in a separate file so it can be reused or replaced
# without modifying the script logic.
$kqlPath = Join-Path $PSScriptRoot 'E8-ML1-PO-06_query.kql'
# Load and flatten KQL query
$query = Get-Content -Path $kqlPath -Raw
$query = $query -replace '\r?\n', ' ' -replace '\s{2,}', ' '
# Build payload correctly
$payload = @{ Query = $query } | ConvertTo-Json -Compress

# — ADVANCED QUERY ——————————————————————————————————————
$result = Invoke-RestMethod -Method Post -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' -Headers $headers -Body $payload

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
$templatePath = Join-Path $PSScriptRoot 'E8-ML1-PO-06_message.html'
$template     = Get-Content -Raw -Path $templatePath

$stamp   = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template -replace '<!--REPORT_TABLE-->',$htmlTable -replace '<!--STAMP-->',$stamp


# Send the email - @@@ in subject, used to enable email command in Manage Engine Service Desk Plus

$subject = "E8-ML1-PO-06 Compliance Gap - $stamp @@@"

Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp