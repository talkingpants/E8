<#
  Exports:
    Get-E8ClientSecret   – decrypts the secret from file.
    Get-MDATPAuthHeader  – returns a bearer-token header for Defender APIs.
#>

function Get-E8ClientSecret {
    <#
      .SYNOPSIS  Decrypt the DPAPI-protected secret.
      .PARAMETER Path  Path to the encrypted blob.
    #>
    param(
        [string]$Path = 'C:\SECRET\defender.secret'
    )

    if (-not (Test-Path $Path)) {
        throw "Secret file not found: $Path"
    }

    $enc  = [IO.File]::ReadAllBytes($Path)
    $plainBytes = [Security.Cryptography.ProtectedData]::Unprotect(
                    $enc, $null, 'LocalMachine')
    [Text.Encoding]::UTF8.GetString($plainBytes)
}

function Get-MDATPAuthHeader {
    <#
      .SYNOPSIS  Get a Hashtable with Authorization and Content-Type headers.
      .PARAMETER TenantId       Entra ID tenant GUID.
      .PARAMETER ClientId       App registration ID.
      .PARAMETER SecretPath     Path to DPAPI-protected secret blob.
      .PARAMETER ApiBase        Defender API root (optional – default $apiBase if defined).
    #>
    param(
        [Parameter(Mandatory)][string]$TenantId,
        [Parameter(Mandatory)][string]$ClientId,
        [string]$SecretPath = 'C:\SECRET\defender.secret',
        [string]$ApiBase
    )

    $clientSecret = Get-E8ClientSecret -Path $SecretPath
    $scope        = 'https%3A%2F%2Fapi.securitycenter.microsoft.com%2F.default'
    $body         = "client_id=$ClientId&scope=$scope&client_secret=$clientSecret&grant_type=client_credentials"

    $token = (Invoke-RestMethod -Method Post `
                -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                -Body $body -ContentType 'application/x-www-form-urlencoded').access_token

    @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
}

Export-ModuleMember -Function Get-E8ClientSecret,Get-MDATPAuthHeader
