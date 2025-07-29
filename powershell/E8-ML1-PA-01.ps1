# E8-ML1-PA-01.ps1

# CONFIG
. (Join-Path $PSScriptRoot 'E8-config.ps1')
. (Join-Path $PSScriptRoot 'E8-Defender_auth.ps1')

# — AUTH HEADER
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ClientSecret $secret

# — LOAD & SANITIZE KQL 
$kqlPath = Join-Path $PSScriptRoot 'E8-ML1-PA-01_query.kql'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }
$query = Get-Content -Path $kqlPath -Raw
$query = $query -replace '\r?\n', ' ' -replace '\s{2,}', ' '

# — BUILD PAYLOAD & RUN QUERY —————————————————————————————————————
$payload = @{ Query = $query } | ConvertTo-Json -Compress
$result  = Invoke-RestMethod `
    -Method Post `
    -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' `
    -Headers $headers `
    -Body $payload

# — REPORT BUILD & SEND ————————————————————————————————————————
if ($result.Results.Count) {
    $htmlTable = $result.Results | Select-Object DeviceName, OSPlatform, LastSeen, @{Name='IPs';Expression={ ($_.IPs -join '<br/>') }} |
    ConvertTo-Html -Fragment |
    Out-String
}
else {
    $htmlTable = "<p>No devices found that can be onboarded.</p>"
}

# un-escape the <br/> so they actually render as line breaks
$htmlTable = $htmlTable -replace '&lt;br/&gt;', '<br/>'

$templatePath = Join-Path $PSScriptRoot 'E8-ML1-PA-01_message.html'
if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
$template = Get-Content -Raw -Path $templatePath

$stamp    = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template `
    -replace '<!--REPORT_TABLE-->', $htmlTable `
    -replace '<!--STAMP-->', $stamp

$subject = "E8-ML1-PA-01 Onboarding Devices Report - $stamp @@@"

Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
