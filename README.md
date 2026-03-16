# 🚀 Universal Intune & Entra ID Device Cleanup Tool
[![Microsoft MVP](https://img.shields.io/badge/Microsoft-MVP-0078d4.svg)](https://mvp.microsoft.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.2+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📌 Overview
Managing stale device records is a critical task for maintaining security hygiene and optimizing license usage. This script provides an **industrialized, tenant-agnostic** solution for independent consultants and IT Admins to clean up inactive devices across multiple platforms.

By targeting both **Microsoft Intune** and **Entra ID** (Azure AD) simultaneously, it ensures that no "ghost" objects remain in the directory after decommissioning.

---

## ✨ Key Features
* **Multi-Platform Support:** Granularly select Windows, iOS, Android, or macOS.
* **Dynamic Thresholds:** Set inactivity limits (in days) on the fly.
* **Atomic Deletions:** Cleans the Intune Managed Device object *and* the associated Entra ID object.
* **Flexible Reporting:** Local JSON logs or automated **Azure Blob Storage** backup.

---

## 🛡️ Safety & Exclusion Groups
This script is designed for production safety. A primary feature is the **Optional Exclusion Group**.

> [!IMPORTANT]
> **How Exclusions Work:** By providing an Entra ID Group Object ID during the prompts, the script will automatically query all transitive members of that group. If a stale device's `AzureADDeviceId` is found within that group, **it will be skipped**, even if it meets the inactivity threshold.
>
> **Use cases for Exclusions:**
> * Protecting VIP or Executive devices.
> * Exempting specialized industrial hardware (kiosks, digital signage).
> * Preserving Autopilot-registered devices that rarely sync.

---

## 🛠 Prerequisites

### 1. Microsoft Graph Permissions
Your Azure App Registration (Service Principal) requires the following **Application** permissions:

| Permission | Type | Reason |
| :--- | :--- | :--- |
| `DeviceManagementManagedDevices.ReadWrite.All` | Application | To read and delete Intune devices |
| `Device.ReadWrite.All` | Application | To delete Entra ID objects |
| `Group.Read.All` | Application | To check membership of the exclusion group |

### 2. PowerShell Modules
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Az.Storage -Scope CurrentUser
```

---

## 🚀 Execution Guide

### 1. Pre-Execution
Ensure you have your **Tenant ID**, **Client ID**, and **Client Secret** ready from your Azure App Registration.

### 2. Running the Script
Run the script by passing the mandatory authentication parameters:
```powershell
.\IntuneCleanup.ps1 -TenantId "yourtenant.onmicrosoft.com" `
                    -ClientId "00000000-0000-0000-0000-000000000000" `
                    -ClientSecret "YourSecretValue"
```

### 3. Interactive Prompts
Once started, the script will prompt you for the following configuration:

* **Platform Selection:** `1` Windows | `2` iOS | `3` Android | `4` macOS | `5` All
* **Inactivity Threshold:** Enter the number of days (e.g., `90`).
* **Exclusion Group (Optional):** Paste the Entra ID Group Object ID or press Enter to skip.
* **Blob Storage Backup (Optional):** If you select `y`, you will be prompted for:
  * Storage Account Name
  * Storage Account Key
  * Container Name

---

## 📖 Practical Scenarios & Examples

### Scenario A: Strict Windows Governance
**Goal:** Clean up Windows laptops inactive for more than 3 months.

| Parameter | Value |
| :--- | :--- |
| Platform Selection | `1` (Windows) |
| Threshold | `90` days |
| Exclusion Group | *(leave blank)* |
| Storage Backup | `n` |

**Result:** Fast, local cleanup of stale Windows workstations with a local JSON log generated in the script folder.

---

### Scenario B: Mobile Fleet Refresh with VIP Protection
**Goal:** Clean up iOS and Android devices inactive for 6 months, but protect the CEO and Board of Directors.

| Parameter | Value |
| :--- | :--- |
| Platform Selection | `2,3` (iOS & Android) |
| Threshold | `180` days |
| Exclusion Group | `047b1b51-1f83-48c8-a32a-2c0be575c293` |
| Storage Backup | `y` |

**Result:** Deletes stale mobile devices, ignores anyone in the VIP group, and sends a permanent audit log to Azure Blob Storage for compliance.

---

### Scenario C: Full Tenant Spring Cleaning
**Goal:** Wipe every device older than 1 year across all platforms.

| Parameter | Value |
| :--- | :--- |
| Platform Selection | `5` (All Platforms) |
| Threshold | `365` days |
| Exclusion Group | *(optional)* |
| Storage Backup | `y` |

**Result:** A comprehensive sweep of the entire tenant with industrial logging for long-term auditing.

---

## 📊 Technical Logic Breakdown
* **Pagination Handling:** Uses a generic `Get-GraphData` function to handle `@odata.nextLink` automatically, ensuring no devices are missed in large environments.
* **Error Resiliency:** Wrapped in `Try/Catch` blocks; if a single device deletion fails, the script logs the error and continues the batch rather than crashing.
* **Validation:** Checks Storage Context validity before starting the cleanup process to prevent post-execution data loss.

---

## 🛡️ Disclaimer

> [!WARNING]
> **Permanent Deletion:** This tool performs irreversible deletions in Intune and Entra ID. The script is provided with commented lines for the deletion action. Please uncomment these lines to enable the deletion and not being in a report-mode only.
>
> **Best Practice:** Always run with a high threshold (e.g., `270` days) first and review the generated JSON report before moving to aggressive cleanup cycles.
