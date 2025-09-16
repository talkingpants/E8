# ------------------------------------------------------------
# Environment configuration – **NO SECRETS HERE**
# ------------------------------------------------------------
$tenantId     = '...'
$clientId     = '...'

# Defender API root (rarely changes)
$apiBase = 'https://api.securitycenter.microsoft.com'

# Mail settings for reports via Microsoft Graph
# Requires the app to have the Mail.Send application permission
$mailFrom = 'sender@contoso.com'
$mailTo   = @('servicedesk@contoso.com')

# Optional: distinct credentials for the Microsoft Graph app
# Uncomment and set if the Graph app differs from the Defender app
#$graphTenantId  = '...'
#$graphClientId  = '...'
