<#
  One-time setup: run **on the target server**.
  Keeps the key bound to the server’s machine key; stealing the file alone isn’t enough to decrypt it.
  Prompts for the client secret from the Entra ID app registration and
  stores it encrypted (DPAPI – LocalMachine scope) at C:\SECRET\defender.secret.
#>

$secretPath = 'C:\SECRET\defender.secret'
New-Item -ItemType Directory -Path (Split-Path $secretPath) -Force | Out-Null

$secure = Read-Host -Prompt 'Enter Defender Client Secret' -AsSecureString
$plain  = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$bytes  = [Text.Encoding]::UTF8.GetBytes($plain)

$encrypted = [Security.Cryptography.ProtectedData]::Protect(
               $bytes, $null, 'LocalMachine')
[IO.File]::WriteAllBytes($secretPath, $encrypted)

Write-Host "Encrypted secret written to $secretPath"
