# E8-ML1-PA-09.ps1
# Imports
. (Join-Path $PSScriptRoot 'E8-config.ps1')
Import-Module (Join-Path $PSScriptRoot 'E8-Defender_auth.psm1')
Import-Module (Join-Path $PSScriptRoot 'E8-Common.psm1')

# Resolve sibling dirs
$paths = Get-E8Paths -ScriptRoot $PSScriptRoot
$kqlPath = Join-Path $paths.KqlDir 'E8-ML1-PA-09_query.kql'
$templatePath = Join-Path $paths.MsgDir 'E8-ML1-PA-09_message.html'
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

if ($result.Results.Count -gt 0) {
    $rows = $result.Results | Sort-Object OSPlatform, DeviceName -Descending

    $htmlTable = $rows |
        Select-Object DeviceName, OSPlatform, SoftwareVendor, SoftwareName, SoftwareVersion, EndOfSupportDate |
        ConvertTo-Html -Fragment |
        Out-String

    # Inject into template and send
    if (-not (Test-Path $templatePath)) { throw "Template file not found: $templatePath" }
    $template = Get-Content -Raw -Path $templatePath

    # send email only when there are results (your change was correct)
    $stamp   = (Get-Date).ToString('yyyy-MM-dd')
    $bodyHtml = $template -replace '<!--REPORT_TABLE-->', $htmlTable -replace '<!--STAMP-->', $stamp
    $subject = "E8-ML1-PA-09 End Of Support (EOS) applications - $stamp @@@"

    $mail = New-Object System.Net.Mail.MailMessage
    $mail.From = $mailFrom
    $mailTo | ForEach-Object { $mail.To.Add($_) }
    $mail.Subject = $subject
    $mail.Body = $bodyHtml
    $mail.IsBodyHtml = $true

    $smtpClient = New-Object System.Net.Mail.SmtpClient($smtp)
    $smtpClient.Send($mail)
}
else {
    Throw 'No findings. Email not sent.'
}



