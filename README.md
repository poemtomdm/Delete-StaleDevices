# 🚀 Universal Intune & Entra ID Device Cleanup Tool

[![Microsoft MVP](https://img.shields.io/badge/Microsoft-MVP-0078d4.svg)](https://mvp.microsoft.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.2+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📌 Overview
Managing stale device records is a critical task for maintaining security hygiene and optimizing license usage. This script provides an **industrialized, tenant-agnostic** solution for independent consultants and IT Admins to clean up inactive devices across multiple platforms.

By targeting both **Microsoft Intune** and **Entra ID** (Azure AD) simultaneously, it ensures that no "ghost" objects remain in the directory after decommissioning.

[Image of Microsoft Intune and Entra ID integration architecture]

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
