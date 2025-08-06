<#
  Common helpers shared by all PA scripts.
  - Get-E8Paths      : resolve base/kql/message dirs from a script under E8\powershell
  - Invoke-E8Query   : call Defender Advanced Hunting with readable error output
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

Export-ModuleMember -Function Get-E8Paths, Invoke-E8Query
