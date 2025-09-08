<#
  Common helpers shared by all PA scripts.
  - Get-E8Paths      : resolve base/kql/message dirs from a script under E8\powershell
  - Invoke-E8Query   : call Defender Advanced Hunting with readable error output
  - Send-E8ExchangeOnlineMail : send HTML email via Microsoft Graph
#>

function Get-E8Paths {
    param([Parameter(Mandatory)][string]$ScriptRoot)

    $base = Split-Path -Path $ScriptRoot -Parent
    [pscustomobject]@{
        Base    = $base
        KqlDir  = Join-Path $base 'kql'
        MsgDir  = Join-Path $base 'message'
    }
}

function Invoke-E8Query {
    param(
        [Parameter(Mandatory)][string]$Query,
        [Parameter(Mandatory)][hashtable]$Headers,
        [string]$ApiRoot = 'https://api.securitycenter.microsoft.com'
    )

    $uri = "$ApiRoot/api/advancedqueries/run"
    $payload = @{ Query = $Query } | ConvertTo-Json -Compress

    try {
        Invoke-RestMethod -Method Post -Uri $uri -Headers $Headers -Body $payload
    }
    catch {
        $resp = $_.Exception.Response
        if ($resp) {
            try {
                $reader = New-Object IO.StreamReader($resp.GetResponseStream())
                $body   = $reader.ReadToEnd()
                throw "AdvancedQuery error: $body"
            } catch { throw }
        }
        throw
    }
}

function Send-E8ExchangeOnlineMail {
    <#
      .SYNOPSIS  Send an HTML email using Microsoft Graph.
      .PARAMETER TenantId   Entra ID tenant GUID.
      .PARAMETER ClientId   App registration ID.
      .PARAMETER From       Sender email address.
      .PARAMETER To         Recipient email addresses.
      .PARAMETER Subject    Email subject.
      .PARAMETER BodyHtml   HTML body content.
      .PARAMETER SecretPath Path to DPAPI-protected secret blob.
    #>
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [Parameter(Mandatory)][string]$From,
        [Parameter(Mandatory)][string[]]$To,
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$BodyHtml,
        [string]$SecretPath = 'C:\SECRET\defender.secret'
    )

    $headers = Get-E8GraphAuthHeader -TenantId $TenantId -ClientId $ClientId -SecretPath $SecretPath
    $uri     = "https://graph.microsoft.com/v1.0/users/$From/sendMail"

    $payload = @{ 
        Message = @{ 
            Subject = $Subject
            Body    = @{ ContentType = 'HTML'; Content = $BodyHtml }
            ToRecipients = $To | ForEach-Object { @{ EmailAddress = @{ Address = $_ } } }
        }
    } | ConvertTo-Json -Depth 4

    Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $payload
}

Export-ModuleMember -Function Get-E8Paths, Invoke-E8Query, Send-E8ExchangeOnlineMail
