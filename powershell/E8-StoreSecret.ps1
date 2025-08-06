<#
  One-time setup: run on the target server.
  Prompts for the Entra ID app client secret and stores it encrypted
  with DPAPI (LocalMachine scope) at C:\SECRET\defender.secret.
#>

$secretPath = 'C:\SECRET\defender.secret'

# Try to load the ProtectedData type (works across PS 5.1 and PS 7)
try {
    # First try the specific assembly (PS 7), then the legacy umbrella (PS 5.1)
    Add-Type -AssemblyName System.Security.Cryptography.ProtectedData -ErrorAction Stop
} catch {
    try {
        Add-Type -AssemblyName System.Security -ErrorAction Stop
    } catch {
        throw "Cannot load System.Security.Cryptography.ProtectedData. Check your PowerShell/.NET install on this host."
    }
}

# Create folder
$null = New-Item -ItemType Directory -Path (Split-Path -Path $secretPath) -Force

# Prompt
$secure = Read-Host -Prompt 'Enter Defender Client Secret' -AsSecureString
if (-not $secure) { throw 'No secret entered.' }

# Convert SecureString -> bytes (and zero the BSTR afterwards)
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
    $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# UTF8 bytes
$bytes = [Text.Encoding]::UTF8.GetBytes($plain)

# Encrypt with DPAPI (machine scope)
$encrypted = [System.Security.Cryptography.ProtectedData]::Protect(
    $bytes,
    $null,
    [System.Security.Cryptography.DataProtectionScope]::LocalMachine
)

# Write to disk
[IO.File]::WriteAllBytes($secretPath, $encrypted)

Write-Host "Encrypted secret written to $secretPath"
