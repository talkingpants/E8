function Get-MDATPAuthHeader {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret
    )

    $body = "client_id=$ClientId&scope=https%3A%2F%2Fapi.securitycenter.microsoft.com%2F.default&" +
            "client_secret=$ClientSecret&grant_type=client_credentials"
    $token = (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
              -Body $body -ContentType 'application/x-www-form-urlencoded').access_token
    @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
}