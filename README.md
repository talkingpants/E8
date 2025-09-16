# E8

Scripts and templates for generating Essential Eight (E8) compliance reports using Microsoft Defender Advanced Hunting. This repository also leverages Microsoft Graph to deliver email reports, eliminating the need for an SMTP server.

## Repository structure

- **powershell/** – PowerShell modules and report scripts.
  - `E8-config.ps1` – Defines tenant, client, API base, and mail settings
  - `E8-Common.psm1` – Utilities for resolving paths and running Defender Advanced Hunting queries
  - `E8-Defender_auth.psm1` – Decrypts the DPAPI-protected secret from the HKCU registry and builds bearer-token headers for Defender APIs
  - `E8-StoreSecret.ps1` – One‑time helper to encrypt and store the Defender app client secret in the user's HKCU registry hive via DPAPI
  - `E8-ML1-PA-01.ps1` (and similar scripts) – Load a KQL query and HTML template, run the query, and email a formatted report via Microsoft Graph
- **kql/** – Kusto Query Language files used by the report scripts.
  Example: `E8-ML1-PA-01_query.kql` lists devices that can be onboarded and their IP addresses
- **message/** – HTML templates for report emails, containing instructions, report placeholders, and ticketing metadata

## Setup

1. [Prepare Microsoft Entra ID and Defender](#entra-and-defender-setup) by registering an app with the required API permissions.
2. Customize `powershell/E8-config.ps1` with your tenant ID, client ID, API base, and mail settings.
3. Run `powershell/E8-StoreSecret.ps1` once to encrypt and store the Defender app client secret in the current user's `HKCU\Software\E8` registry key using DPAPI.
4. Confirm the host has network access to the Defender APIs and Microsoft Graph.

## Entra and Defender setup

1. In the Microsoft Entra admin center, register a new application for these reports.
2. Under **API permissions**, add application permissions and grant admin consent for:
   - **Microsoft Graph** → `Mail.Send`
   - **Microsoft Threat Protection** → `AdvancedHunting.Read.All`
3. Create a client secret and record the secret value, client ID, and tenant ID.
4. Ensure the organization has Microsoft Defender enabled and licensed for Advanced Hunting queries.
5. Run `powershell/E8-StoreSecret.ps1` to encrypt the client secret into the user's `HKCU\Software\E8` registry location.

## Usage

1. Execute the desired report script from `powershell/` (e.g., `E8-ML1-PA-01.ps1`).
2. The script resolves the relevant KQL query and HTML template, obtains an auth token, runs the query, injects the results into the template, and emails the report via Microsoft Graph.
3. Schedule scripts with Task Scheduler or another automation tool as needed.

## License

Distributed under the GNU General Public License v3.0
