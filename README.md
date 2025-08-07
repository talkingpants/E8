# E8

Scripts and templates for generating Essential Eight (E8) compliance reports using Microsoft Defender Advanced Hunting. This repository also leverages Microsoft Graph to deliver email reports, eliminating the need for an SMTP server.

## Repository structure

- **powershell/** – PowerShell modules and report scripts.
  - `E8-config.ps1` – Defines tenant, client, secret path, API base, and mail settings
  - `E8-Common.psm1` – Utilities for resolving paths and running Defender Advanced Hunting queries
  - `E8-Defender_auth.psm1` – Decrypts the DPAPI-protected secret and builds bearer-token headers for Defender APIs
  - `E8-StoreSecret.ps1` – One‑time helper to encrypt and store the Defender app client secret via DPAPI
  - `E8-ML1-PA-01.ps1` (and similar scripts) – Load a KQL query and HTML template, run the query, and email a formatted report via Microsoft Graph
- **kql/** – Kusto Query Language files used by the report scripts.  
  Example: `E8-ML1-PA-01_query.kql` lists devices that can be onboarded and their IP addresses
- **message/** – HTML templates for report emails, containing instructions, report placeholders, and ticketing metadata

## Setup

1. Customize `powershell/E8-config.ps1` with your tenant ID, client ID, secret path, API base, and mail settings.
2. Run `powershell/E8-StoreSecret.ps1` once to encrypt and store the Defender app client secret using DPAPI.
3. Confirm the host has network access to the Defender APIs and Microsoft Graph.

## Usage

1. Execute the desired report script from `powershell/` (e.g., `E8-ML1-PA-01.ps1`).
2. The script resolves the relevant KQL query and HTML template, obtains an auth token, runs the query, injects the results into the template, and emails the report via Microsoft Graph.
3. Schedule scripts with Task Scheduler or another automation tool as needed.

## License

Distributed under the GNU General Public License v3.0

