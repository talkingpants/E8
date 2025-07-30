# E8-ML1-PA-06.ps1

# Load config and Defender auth helper
. (Join-Path $PSScriptRoot 'E8-config.ps1')
. (Join-Path $PSScriptRoot 'E8-Defender_auth.ps1')

# Acquire auth header
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -ClientSecret $secret

# Load and sanitise the KQL
$kqlPath = Join-Path $PSScriptRoot 'E8-ML1-PA-06_query.kql'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }

$query = Get-Content -Raw -Path $kqlPath
$query = $query -replace '(?m)^\s*//.*$',''
$query = $query -replace '\r?\n',' '
$query = $query -replace '\s{2,}',' '
$query = $query.Trim()

# Execute
$payload = @{ Query = $query } | ConvertTo-Json -Compress
try {
    $result = Invoke-RestMethod -Method Post -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' -Headers $headers -Body $payload
}
catch {
    try {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object IO.StreamReader($stream)
        $err    = $reader.ReadToEnd()
        throw "AdvancedQuery error: $err"
    } catch {
        throw
    }
}

# No findings -> no email
if (-not $result -or -not $result.Results -or $result.Results.Count -eq 0) {
    Write-Host 'ML1-PA-06: No findings. Email not sent.'
    return
}

# Build the HTML table (aligns with your KQL columns)
$rows = $result.Results | Sort-Object OSPlatform, DeviceName

$htmlTable = $rows |
    Select-Object `
        DeviceName, `
        OSPlatform, `
        VulnCount, `
        CriticalCount, `
        @{Name = 'OldestVulnDate'; Expression = { $_.OldestVulnDate }}, `
        @{Name = 'CVEs';          Expression = { ($_.VulnList | Sort-Object | Select-Object -Unique) -join ', ' }} |
    ConvertTo-Html -Fragment |
    Out-String

# Inject into template and send
$templatePath = Join-Path $PSScriptRoot 'E8-ML1-PA-06_message.html'
if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
$template = Get-Content -Raw -Path $templatePath

$stamp    = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp

$subject  = "E8-ML1-PA-06 Internet-facing devices with Non-Critical vulns older than 14-days - $stamp @@@"
Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
