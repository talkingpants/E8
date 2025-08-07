# ------------------------------------------------------------
# Environment configuration – **NO SECRETS HERE**
# ------------------------------------------------------------
$tenantId     = '...'
$clientId     = '...'

# Path to the DPAPI-protected secret created by E8-StoreSecret.ps1
$secretPath = 'C:\SECRET\defender.secret'

# Defender API root (rarely changes)
$apiBase = 'https://api.securitycenter.microsoft.com'

# Mail settings for reports
$smtp         = 'mail.contoso.com'
$mailFrom     = 'sender@contoso.com'
$mailTo       = @('servicedesk@contoso.com')
