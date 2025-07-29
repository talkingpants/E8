# E8-ML1-PA-04-EndpointSecurity.ps1

. (Join-Path $PSScriptRoot 'E8-config.ps1')
. (Join-Path $PSScriptRoot 'E8-Defender_auth.ps1')

$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ClientSecret $secret

$kqlPath = Join-Path $PSScriptRoot 'E8-ML1-PA-04-EndpointSecurity_query.kql'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }
$query  = Get-Content -Raw -Path $kqlPath
$query  = $query -replace '(?m)//.*$',''   # strip any // comments if present
$query  = $query -replace '\r?\n',' '      # flatten newlines
$query  = $query -replace '\s{2,}',' '     # squeeze spaces
$payload = @{ Query = $query.Trim() } | ConvertTo-Json -Compress

$result  = Invoke-RestMethod -Method Post -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' -Headers $headers -Body $payload

if ($result.Results.Count) {
    $htmlTable = $result.Results |
        Select-Object `
            DeviceName,
            @{Name='IPs'; Expression = { ($_.IPs -join '<br/>') }},
            DefenderEnabled,
            DefenderUpToDate,
            WindowsDefenderFirewallEnabled,
            ActiveProfile |
        ConvertTo-Html -Fragment |
        Out-String

    # decode &lt;br/&gt; so the breaks render
    Add-Type -AssemblyName System.Web
    $htmlTable = [System.Web.HttpUtility]::HtmlDecode($htmlTable)
}
else {
    $htmlTable = "<p>No devices with Endpoint Security issues found. GOOD BOY!</p>"
}

$templatePath = Join-Path $PSScriptRoot 'E8-ML1-PA-04-EndpointSecurity_message.html'
if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
$template = Get-Content -Path $templatePath -Raw

$stamp    = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

$subject = "E8-ML1-PA-04 EndpointSecurity Vuln Report - $stamp @@@"
Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
