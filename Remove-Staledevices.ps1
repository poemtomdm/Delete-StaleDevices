Param(
    [Parameter(Mandatory=$true)] [string]$TenantId,
    [Parameter(Mandatory=$true)] [string]$ClientId,
    [Parameter(Mandatory=$true)] [string]$ClientSecret
)

# 1. Selection & Thresholds
Write-Host "--- Configuration ---" -ForegroundColor Cyan
Write-Host "1. Windows | 2. iOS | 3. Android | 4. macOS | 5. All Platforms"
$choice = Read-Host "Select platform(s) (e.g., 1,2)"
$days   = Read-Host "Enter inactivity threshold (days)"

$platformMap = @{ "1"="Windows"; "2"="iOS"; "3"="Android"; "4"="macOS" }
$selectedPlatforms = if ($choice -eq "5") { $platformMap.Values } else { $choice.Split(',').ForEach({ $platformMap[$_.Trim()] }) }

# 2. Fully Optional Exclusion
$ExclusionGroupId = Read-Host "Enter Exclusion Group ID (Optional - Press Enter to skip)"

# 3. Fully Optional Storage
$doBackup = Read-Host "Backup report to Azure Blob Storage? (y/n)"
$ctx = $null
$containerName = ""
if ($doBackup -eq 'y') {
    $storageAccount = Read-Host "Enter Storage Account Name"
    $storageKey     = Read-Host "Enter Storage Account Key"
    $containerName  = Read-Host "Enter Container Name"
    try {
        $ctx = New-AzStorageContext -StorageAccountName $storageAccount -StorageAccountKey $storageKey -ErrorAction Stop
        $null = Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction Stop
    } catch {
        Write-Warning "Storage validation failed. Script will proceed with local report only."
        $doBackup = 'n'
    }
}

# 4. Auth & Helper
$SecSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential($ClientId, $SecSecret)
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Creds

Function Get-GraphData {
    Param($Uri)
    $Results = @()
    while ($Uri) {
        $Response = Invoke-MgGraphRequest -Method GET -Uri $Uri
        $Results += $Response.value
        $Uri = $Response.'@odata.nextLink'
    }
    return $Results
}

# 5. Conditional Data Gathering
$ExclusionIds = @()
if (-not [string]::IsNullOrWhiteSpace($ExclusionGroupId)) {
    Write-Host "Fetching exclusion list..."
    $ExclusionIds = (Get-GraphData -Uri "https://graph.microsoft.com/beta/groups/$ExclusionGroupId/transitiveMembers").id
}

$FilterDate = (Get-Date).AddDays(-$days).ToString("yyyy-MM-ddTHH:mm:ssZ")
$PlatformFilter = ($selectedPlatforms | ForEach-Object { "operatingSystem eq '$_'" }) -join " or "
$FinalFilter = "($PlatformFilter) and lastSyncDateTime lt $FilterDate"

Write-Host "Gathering stale devices..." -ForegroundColor Yellow
$StaleDevices = Get-GraphData -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=$FinalFilter&`$ConsistencyLevel=eventual"

# 6. Execution Loop
$DeletedReport = @()
foreach ($Device in $StaleDevices) {
    # Get Entra ID
    $EntraLookup = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/devices?`$filter=deviceId eq '$($Device.azureADDeviceId)'"
    $ObjectId = $EntraLookup.value[0].id

    if (-not $ObjectId) { continue }

    # Safe Exclusion Check: Only runs if the list isn't empty
    if ($ExclusionIds.Count -gt 0 -and $ExclusionIds -contains $ObjectId) {
        Write-Host "Skipping $($Device.deviceName) (Member of Exclusion Group)" -ForegroundColor Gray
        continue
    }

    try {
        Write-Host "DELETING: $($Device.deviceName) ($($Device.operatingSystem))" -ForegroundColor Red
        #Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($Device.id)"
        #Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/beta/devices/$ObjectId"
        
        $DeletedReport += [pscustomobject]@{
            DeviceName = $Device.deviceName
            OS         = $Device.operatingSystem
            LastSync   = $Device.lastSyncDateTime
            DateDeleted = Get-Date -Format "yyyy-MM-dd HH:mm"
        }
    } catch {
        Write-Warning "Failed to delete $($Device.deviceName): $($_.Exception.Message)"
    }
}

# 7. Final Report Logic
if ($DeletedReport.Count -gt 0) {
    $FileName = "Cleanup_$(Get-Date -Format 'yyyyMMdd_HHmm').json"
    $FilePath = Join-Path $PSScriptRoot $FileName
    $DeletedReport | ConvertTo-Json | Out-File -FilePath $FilePath
    Write-Host "Local report generated: $FileName" -ForegroundColor Green

    if ($doBackup -eq 'y' -and $ctx) {
        Set-AzStorageBlobContent -File $FilePath -Container $containerName -Blob "Reports/$FileName" -Context $ctx -Force
        Write-Host "Report successfully uploaded to Azure Storage." -ForegroundColor Green
    }
} else {
    Write-Host "No devices found matching the criteria. Nothing deleted." -ForegroundColor Yellow
}