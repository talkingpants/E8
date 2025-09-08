# PowerShell scripts

## Grant required permissions
1. Register an application in Microsoft Entra ID.
2. Under **API permissions**, add application permissions and grant admin consent for:
   - **Microsoft Graph** → `Mail.Send`
   - **Microsoft Threat Protection** → `AdvancedHunting.Read.All`
3. Create a client secret for each app.

## Configure `E8-config.ps1`
1. Update tenant ID, client ID, and secret path for the Defender app:
   - `$tenantId`
   - `$clientId`
   - `$secretPath`
2. Set mail sender and recipients:
   - `$mailFrom`
   - `$mailTo`
3. If a separate Graph app is used, also configure:
   - `$graphTenantId`
   - `$graphClientId`
   - `$graphSecretPath`
4. Run `E8-StoreSecret.ps1` once for each secret path to encrypt the client secret.

After configuration, execute the desired report scripts from this directory.
