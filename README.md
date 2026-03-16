# 🚀 Universal Intune & Entra ID Device Cleanup Tool

[![Microsoft MVP](https://img.shields.io/badge/Microsoft-MVP-0078d4.svg)](https://mvp.microsoft.com/)
[![PowerShell](https://img.shields.io/badge/PowerShell-7.2+-blue.svg)](https://github.com/PowerShell/PowerShell)

## 📌 Overview
Managing stale device records is a critical task for maintaining security hygiene and optimizing license usage. This script provides an **industrialized, tenant-agnostic** solution for independent consultants and IT Admins to clean up inactive devices across multiple platforms.

By targeting both **Microsoft Intune** and **Entra ID** (Azure AD) simultaneously, it ensures that no "ghost" objects remain in the directory after decommissioning.

[Image of Microsoft Intune and Entra ID integration architecture]

---

## ✨ Key Features
* **Multi-Platform Support:** Granularly select Windows, iOS, Android, or macOS.
* **Dynamic Thresholds:** Set inactivity limits (in days) on the fly.
* **Safe-to-Delete Logic:** * **Optional Exclusion Groups:** Protect VIP or specialized hardware by providing a Group ID.
    * **Entra Verification:** Confirms the Entra ID object exists before attempting deletion.
* **Flexible Reporting:**
    * **Local JSON Logs:** Generated automatically for every run.
    * **Optional Azure Blob Backup:** Industrial-grade logging to a storage container of your choice.

---

## 🛠 Prerequisites

### 1. Microsoft Graph Permissions
Your Azure App Registration (Service Principal) requires the following **Application** permissions:
* `DeviceManagementManagedDevices.ReadWrite.All`
* `Device.ReadWrite.All`
* `Group.Read.All` (Required only if using the exclusion feature)

### 2. PowerShell Modules
```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
Install-Module Az.Storage -Scope CurrentUser
