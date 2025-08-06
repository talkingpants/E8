# E8-ML1-PA-04-EndpointSecurity.ps1
# Imports
. (Join-Path $PSScriptRoot 'E8-config.ps1')
Import-Module (Join-Path $PSScriptRoot 'E8-Defender_auth.psm1')
Import-Module (Join-Path $PSScriptRoot 'E8-Common.psm1')

# Resolve sibling dirs
$paths = Get-E8Paths -ScriptRoot $PSScriptRoot
$kqlPath = Join-Path $paths.KqlDir 'E8-ML1-PA-04-EndpointSecurity_query.kql'
$templatePath = Join-Path $paths.MsgDir 'E8-ML1-PA-04-EndpointSecurity_message.html'
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

if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
$template = Get-Content -Path $templatePath -Raw

$stamp    = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

$subject = "E8-ML1-PA-04 EndpointSecurity Vuln Report - $stamp @@@"
Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
