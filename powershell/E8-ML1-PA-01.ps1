# E8-ML1-PA-01.ps1
# ---------------------------------------------------------------------------
# Generates the “devices that can be onboarded” report.
# Folder layout:
#   this script  → E8\powershell
#   .kql files   → E8\kql
#   .html templates → E8\message
# ---------------------------------------------------------------------------

# --- CONFIG & AUTH HELPERS -------------------------------------------------
. (Join-Path $PSScriptRoot 'E8-config.ps1')        # <— contains $tenantId, $clientId, $secretPath, etc.
. (Join-Path $PSScriptRoot 'E8-Defender_auth.ps1') # <— Get-MDATPAuthHeader / DPAPI secret decrypt

# ---------------------------------------------------------------------------
# Resolve base / sibling directories (new layout support)
# ---------------------------------------------------------------------------
$baseDir = Split-Path $PSScriptRoot -Parent   # …\E8
$kqlDir  = Join-Path $baseDir 'kql'          # …\E8\kql
$msgDir  = Join-Path $baseDir 'message'      # …\E8\message

# --- AUTH HEADER (secret auto-loaded via secretPath in E8-config.ps1) ------
$headers = Get-MDATPAuthHeader -TenantId $tenantId -ClientId $clientId -SecretPath $secretPath

# --- LOAD & SANITISE KQL ---------------------------------------------------
$kqlPath = Join-Path $kqlDir 'E8-ML1-PA-01_query.kql'
if (-not (Test-Path $kqlPath)) { throw "Query file not found: $kqlPath" }

$query  = Get-Content -Raw -Path $kqlPath
$query  = $query -replace '(?m)//.*$',''   # strip // comments
$query  = $query -replace '\r?\n',' '      # flatten newlines
$query  = $query -replace '\s{2,}',' '     # squeeze spaces

# --- RUN ADVANCED HUNTING --------------------------------------------------
$payload = @{ Query = $query.Trim() } | ConvertTo-Json -Compress
$result  = Invoke-RestMethod `
            -Method Post `
            -Uri 'https://api.securitycenter.microsoft.com/api/advancedqueries/run' `
            -Headers $headers `
            -Body $payload

# --- BUILD HTML TABLE ------------------------------------------------------
if ($result.Results.Count) {
    $htmlTable = $result.Results |
        Select-Object `
            DeviceName,
            OSPlatform,
            LastSeen,
            @{Name='IPs'; Expression = { ($_.IPs -join '<br/>') }} |
        ConvertTo-Html -Fragment |
        Out-String

    # Decode &lt;br/&gt; so line-breaks render
    $htmlTable = $htmlTable -replace '&lt;br/&gt;', '<br/>'
}
else {
    $htmlTable = '<p>No devices found that can be onboarded.</p>'
}

# --- LOAD TEMPLATE & INJECT TABLE -----------------------------------------
$templatePath = Join-Path $msgDir 'E8-ML1-PA-01_message.html'
if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
$template = Get-Content -Raw -Path $templatePath

$stamp    = (Get-Date).ToString('yyyy-MM-dd')
$bodyHtml = $template `
             -replace '<!--REPORT_TABLE-->', $htmlTable `
             -replace '<!--STAMP-->',        $stamp

# --- SEND E-MAIL -----------------------------------------------------------
$subject = "E8-ML1-PA-01 Onboarding Devices Report - $stamp @@@"
Send-MailMessage -To $mailTo -From $mailFrom -Subject $subject -Body $bodyHtml -BodyAsHtml -SmtpServer $smtp
