# PowerShell scripts

## Grant required permissions
1. Register an application in Microsoft Entra ID.
2. Under **API permissions**, add application permissions and grant admin consent for:
   - **Microsoft Graph** → `Mail.Send`
   - **Microsoft Threat Protection** → `AdvancedHunting.Read.All`
3. Create a client secret for each app.

## Configure `E8-config.ps1`
1. Update tenant ID and client ID for the Defender app:
   - `$tenantId`
   - `$clientId`
2. Set mail sender and recipients:
   - `$mailFrom`
   - `$mailTo`
3. If a separate Graph app is used, also configure:
   - `$graphTenantId`
   - `$graphClientId`
4. Run `E8-StoreSecret.ps1` once to encrypt the client secret in the current user's `HKCU\Software\E8` registry key.

After configuration, execute the desired report scripts from this directory.
