# E8-ML1-PA-07-Browsers.ps1

# Load config and authentication helpers
. (Join-Path $PSScriptRoot 'E8-config.ps1')
. (Join-Path $PSScriptRoot 'E8-Defender_auth.ps1')

# Get Authorization header
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ClientSecret $secret

# Load & sanitize the KQL
$kqlPath = Join-Path $PSScriptRoot 'E8-ML1-PA-07-Browser_query.kql'
if (-not (Test-Path $kqlPath)) {
    throw "Query file not found: $kqlPath"
}
$query = Get-Content -Path $kqlPath -Raw
$query = $query -replace '\r?\n', ' ' -replace '\s{2,}', ' '

# Execute the query
$payload = @{ Query = $query } | ConvertTo-Json -Compress
$result = Invoke-RestMethod `
    -Method Post `
    -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' `
    -Headers $headers `
    -Body $payload

# Build the HTML table
if ($result.Results.Count) {
    $htmlTable = $result.Results |
    Select-Object DeviceName,
                  OSPlatform,
                  LastSeen,
                  VulnerabilityCount,
                  ExploitAvailable,
                  @{Name='CVEs'; Expression = { ($_.CVEList -join ', ') }} |
    ConvertTo-Html -Fragment | Out-String
    
    # Inject into the HTML template
    $templatePath = Join-Path $PSScriptRoot 'E8-ML1-PA-07-Browser_message.html'
    if (-not (Test-Path $templatePath)) {
        throw "Template file not found: $templatePath"
    }
    $template = Get-Content -Path $templatePath -Raw

    $stamp = (Get-Date).ToString('yyyy-MM-dd')
    $bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable `
                         -replace '<!--STAMP-->', $stamp

    # Send the report
    $subject = "E8-ML1-PA-07 Browser Vulnerabilities older than 14d - $stamp @@@"
    Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
}
else {
    throw "No devices with Browser vulnerabilities found."
}

