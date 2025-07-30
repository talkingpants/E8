# E8-ML1-PA-09.ps1

. (Join-Path $PSScriptRoot 'E8-config.ps1')
. (Join-Path $PSScriptRoot 'E8-Defender_auth.ps1')

$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ClientSecret $secret

$kqlPath = Join-Path $PSScriptRoot 'E8-ML1-PA-09_query.kql'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }

$query = Get-Content -Path $kqlPath -Raw
$query = $query -replace '(?m)//.*$',''
$query = $query -replace '\r?\n',' '
$query = $query -replace '\s{2,}',' '
$query = $query.Trim()

$payload = @{ Query = $query } | ConvertTo-Json -Compress
$result  = Invoke-RestMethod -Method Post -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' -Headers $headers -Body $payload

if ($result.Results.Count -gt 0) {
    $rows = $result.Results | Sort-Object OSPlatform, DeviceName -Descending

    $htmlTable = $rows |
        Select-Object DeviceName, OSPlatform, SoftwareVendor, SoftwareName, SoftwareVersion, EndOfSupportDate |
        ConvertTo-Html -Fragment |
        Out-String

    # Inject into template and send
    $templatePath = Join-Path $PSScriptRoot 'E8-ML1-PA-09_message.html'
    if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
    $template = Get-Content -Raw -Path $templatePath

    # send email only when there are results (your change was correct)
    $stamp   = (Get-Date).ToString('yyyy-MM-dd')
    $bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp
    Send-MailMessage -To $mailTo -From $mailFrom -Subject "E8-ML1-PA-09 End Of Support (EOS) applications - $stamp @@@" -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
}
else {
    Throw 'No findings. Email not sent.'
}



