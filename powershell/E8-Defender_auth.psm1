<#
  Exports:
    Get-E8ClientSecret - decrypts the secret from the registry.
    Get-MDATPAuthHeader - returns a bearer-token header for Defender APIs.
    Get-E8GraphAuthHeader - returns a bearer-token header for Microsoft Graph.
#>

Add-Type -AssemblyName System.Security

function Get-E8ClientSecret {
    <#
      .SYNOPSIS  Decrypt the DPAPI-protected secret stored in the registry.
    #>

    $regPath   = 'HKCU:\Software\E8'
    $valueName = 'ClientSecret'

    if (-not (Test-Path $regPath)) {
        throw "Registry path not found: $regPath"
    }

    $enc = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction Stop).$valueName
    $plainBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($enc, $null, 'LocalMachine')
    [Text.Encoding]::UTF8.GetString($plainBytes)
}

function Get-MDATPAuthHeader {
    <#
      .SYNOPSIS  Get a Hashtable with Authorization and Content-Type headers.
      .PARAMETER TenantId       Entra ID tenant GUID.
      .PARAMETER ClientId       App registration ID.
      .PARAMETER ApiBase        Defender API root (optional – default $apiBase if defined).
    #>
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [string]$ApiBase
    )

    $clientSecret = Get-E8ClientSecret
    $scope        = 'https%3A%2F%2Fapi.securitycenter.microsoft.com%2F.default'
    $body         = "client_id=$ClientId&scope=$scope&client_secret=$clientSecret&grant_type=client_credentials"

    $token = (Invoke-RestMethod -Method Post `
                -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                -Body $body -ContentType 'application/x-www-form-urlencoded').access_token

    @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
}

function Get-E8GraphAuthHeader {
    <#
      .SYNOPSIS  Get a Hashtable with Authorization and Content-Type headers for Microsoft Graph.
      .PARAMETER TenantId   Entra ID tenant GUID.
      .PARAMETER ClientId   App registration ID.
    #>
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId
    )

    $clientSecret = Get-E8ClientSecret
    $scope        = 'https%3A%2F%2Fgraph.microsoft.com%2F.default'
    $body         = "client_id=$ClientId&scope=$scope&client_secret=$clientSecret&grant_type=client_credentials"

    $token = (Invoke-RestMethod -Method Post `
                -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                -Body $body -ContentType 'application/x-www-form-urlencoded').access_token

    @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
}

Export-ModuleMember -Function Get-E8ClientSecret,Get-MDATPAuthHeader,Get-E8GraphAuthHeader
