# E8-ML1-PA-07-PDF.ps1

. (Join-Path $PSScriptRoot 'E8-config.ps1')
. (Join-Path $PSScriptRoot 'E8-Defender_auth.ps1')

$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ClientSecret $secret

$kqlPath = Join-Path $PSScriptRoot 'E8-ML1-PA-07-PDF_query.kql'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }
$query = Get-Content -Path $kqlPath -Raw
$query = $query -replace '\r?\n', ' ' -replace '\s{2,}', ' '

$payload = @{ Query = $query } | ConvertTo-Json -Compress
$result  = Invoke-RestMethod -Method Post -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' -Headers $headers -Body $payload

if ($result.Results.Count) {
    $htmlTable = $result.Results | Select-Object DeviceName, OSPlatform, LastSeen, VulnerabilityCount, ExploitAvailable, @{Name='CVEs';Expression={ ($_.CVEList -join ', ') }} | ConvertTo-Html -Fragment | Out-String
    $templatePath = Join-Path $PSScriptRoot 'E8-ML1-PA-07-PDF_message.html'
    if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
    $template = Get-Content -Path $templatePath -Raw
    #Send email
    $stamp    = (Get-Date).ToString('yyyy-MM-dd')
    $bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

    $subject = "E8-ML1-PA-07 PDF (Acrobat/Reader) Vulnerabilities older than 14d - $stamp @@@"
    Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
} else {
    throw "No devices with Acrobat/Reader vulnerabilities found."
}


