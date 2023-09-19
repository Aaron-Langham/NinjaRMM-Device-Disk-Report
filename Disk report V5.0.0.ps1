Install-Module -Name Microsoft.Graph -Force

## Generates a Disk Report for all the devices in a specific group.

# Variables From Ninja
$ClientID = "" #String
$ClientSecret = "" #String
$GroupID = 0 #Integer

# Variables to be used for mailing
$MgTenantID = ""
$MgUserID = ""
$MgClientID = ""
$MgValue = ""
$ToAddress = ""
$Subject = "Server Disk Report"

#Gets the API token and creates the headers for subsequent calls
$body = @{
    grant_type = "client_credentials"
    client_id = "$ClientID"
    client_secret = "$ClientSecret"
    redirect_uri = "https://localhost"
    scope = "monitoring"
}

$API_AuthHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$API_AuthHeaders.Add("accept", 'application/json')
$API_AuthHeaders.Add("Content-Type", 'application/x-www-form-urlencoded')

$auth_token = Invoke-RestMethod -Uri https://eu.ninjarmm.com/oauth/token -Method POST -Headers $API_AuthHeaders -Body $body
$access_token = $auth_token | Select-Object -ExpandProperty 'access_token' -EA 0

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept", "application/json")
$headers.Add("Authorization", "Bearer $access_token")


# Sets the Classes for the Device and Disk Reports
class DeviceReport {
    [string]$OrganizationName
    [string]$LocationName
    [string]$Hostname
    [DiskReport[]]$DeviceDiskReport
    [string]$DiskLetter
    [string]$DiskCapacity
    [string]$DiskFreeSpace
    [string]$DiskPercentageUsed
    [string]$NeedsInvestigation
    [string]$TicketCopyPasta
}

class DiskReport{
    [string]$DiskLetter
    [float]$DiskCapacity
    [float]$DiskFreeSpace
    [string]$DiskPercentageUsed
    [bool]$NeedsInvestigation
    [string]$TicketCopyPasta
}

## Main

# Calls Ninja's API and assigns all the device IDs of the devices in the "Disk Report" Group to an array
$deviceIDs = @()
$deviceIDs = Invoke-RestMethod "https://eu.ninjarmm.com/api/v2/group/$GroupID/device-ids" -Method 'GET' -Headers $headers

# Starts a loop to go through every Device ID and put the output into an Array
$fullDiskReport = ForEach ($ID in $deviceIDs){
    # Calls API to get details for the device and assign to variables
    $device = Invoke-RestMethod "https://eu.ninjarmm.com/api/v2/device/$ID" -Method 'GET' -Headers $headers
    $hostname = $device.systemName
    $volumes = $device.volumes
    $orgID = $device.organizationId
    $locID = $device.locationId    
    
    # Calls API to get the Organization the Device Belongs to and assigns to a variable
    $organization = Invoke-RestMethod -Uri "https://eu.ninjarmm.com/api/v2/organization/$orgID" -Method GET -Headers $headers
    $orgName = $organization.name

    # Calls API to get the All Locations in the Organization, find the Location the Device is in and assign it to a variable
    $locations = Invoke-RestMethod -Uri "https://eu.ninjarmm.com/api/v2/organization/$orgID/locations" -Method GET -Headers $headers
    ForEach ($location in $locations){if ($location.id -eq $locID){$locName = $location.name}}

    # Starts a loop to go through every Volume in the device, Only looking at Local Disks and putting the output into an Array
    $DeviceDiskReport = ForEach ($volume in $volumes){
        if ($volume.deviceType -eq "Local Disk"){
            # Assigns values to variables and formats them
            $name = $volume.name
            $capacity = [math]::Round(($volume.capacity / 1GB),2)
            $free = [math]::Round(($volume.freeSpace / 1GB),2)
            # Try/Catch to stop error when capacity is less than 0.5GB
            Try{$PercUsed = [math]::Round((($volume.capacity - $volume.freeSpace) / $volume.capacity)*100,2)}
            Catch{$PercUsed = "Error"}

            # Crates a flag to show whether a volume will need to be investigated
            if (($PercUsed -eq 100) -or ($PercUsed -eq "Error")){$needsIv = $false}
            elseif ($PercUsed -gt 94){$needsIv = $true}
            else {$needsIv = $false}

            # Formats Data to Copy Pasta into Halo Ticket
            if ($needsIv -eq $true){$ticket = ($hostname + " Disk Space on " + $name + " Drive at " + $PercUsed + "% " + $free + "/" + $capacity + "GB")}
            else {$ticket = "N/A"}

            # Creates Object of DiskReport Class and assigns properties
            $DiskReport = [DiskReport]::new()
            $DiskReport.DiskLetter = $name
            $DiskReport.DiskCapacity = $capacity
            $DiskReport.DiskFreeSpace = $free
            $DiskReport.DiskPercentageUsed = $PercUsed
            $DiskReport.NeedsInvestigation = $needsIv
            $DiskReport.TicketCopyPasta = $ticket
            $DiskReport
        }
    }

    # Creates Object of DeviceReport Class and assigns properties
    $DeviceReport = [DeviceReport]::new()
    $DeviceReport.OrganizationName = $orgName
    $DeviceReport.LocationName = $locName
    $DeviceReport.HostName = $hostname
    $DeviceReport.DeviceDiskReport = $DeviceDiskReport
    $DeviceReport
}

# Sorts Array into Alphabetical order
$fullDiskReport = $fullDiskReport | Sort-Object -Property OrganizationName, LocationName, Hostname

$filteredDiskReport = ForEach ($DeviceReport3 in $fullDiskReport){
    $NeedsInvestigation = $false
    ForEach ($DiskReport2 in $DeviceReport3.DeviceDiskReport){if ($DiskReport2.NeedsInvestigation -eq $true){$NeedsInvestigation = $true}}
    if ($NeedsInvestigation -eq $true){$DeviceReport3}
}

# Bit of logic to format the child objects correctly with the parent object, but I don't remember why or how it works, I just know it works
# Just joking I do, but its hard to explain, So: For each Object in the report it will output the Device Data then, For each disk within the device, get the disk data and add it to an array, sort the array then output it

$fullDiskReport1 = ForEach ($DeviceReport1 in $fullDiskReport){
    $DeviceReport1
    $DeviceReport2 = ForEach ($DiskReport1 in $DeviceReport1.DeviceDiskReport){$DiskReport1}
    # Sorts the disks in alphabetical order
    $DeviceReport2 = $DeviceReport2 | Sort-Object -Property DiskLetter
    $DeviceReport2
}

$filteredDiskReport1 = ForEach ($DeviceReport4 in $filteredDiskReport){
    $DeviceReport4
    $DeviceReport5 = ForEach ($DiskReport3 in $DeviceReport4.DeviceDiskReport){$DiskReport3}
    # Sorts the disks in alphabetical order
    $DeviceReport5 = $DeviceReport5 | Sort-Object -Property DiskLetter
    $DeviceReport5
}

$doubleFilteredDiskReport = ForEach ($DeviceReport6 in $filteredDiskReport){
    $DeviceReport6
    $DeviceReport7 = ForEach ($DiskReport4 in $DeviceReport6.DeviceDiskReport){If ($DiskReport4.NeedsInvestigation -eq $true){$DiskReport4}}
    # Sorts the disks in alphabetical order
    $DeviceReport7 = $DeviceReport7 | Sort-Object -Property DiskLetter
    $DeviceReport7
}

# Outputs to html file in current directory
$fullDiskReport1 | ConvertTo-Html -Property OrganizationName, LocationName, Hostname, DiskLetter, DiskFreeSpace, DiskCapacity, DiskPercentageUsed, NeedsInvestigation, TicketCopyPasta | Out-File "./fullDiskReport.html"

$filteredDiskReport1 | ConvertTo-Html -Property OrganizationName, LocationName, Hostname, DiskLetter, DiskFreeSpace, DiskCapacity, DiskPercentageUsed, NeedsInvestigation, TicketCopyPasta | Out-File "./filteredDiskReport.html"

$doubleFilteredDiskReport | ConvertTo-Html -Property OrganizationName, LocationName, Hostname, DiskLetter, DiskFreeSpace, DiskCapacity, DiskPercentageUsed, NeedsInvestigation, TicketCopyPasta | Out-File "./doubleFilteredDiskReport.html"

#$fullDiskReport2 = "./fullDiskReport.html"
#$filteredDiskReport2 = "./filteredDiskReport.html"
#$doubleFilteredDiskReport1 = "./doubleFilteredDiskReport.html"

# Created variables to be used for mailing
$MgValue = ConvertTo-SecureString -String $MgValue -AsPlainText -Force
$Secret = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $MgClientID, $MgValue
Connect-MgGraph -TenantId $MgTenantID -ClientSecretCredential $Secret

$attachmentpath1 = "./fullDiskReport.html"
$attachmentmessage1 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($attachmentpath1))
$attachmentname1 = (Get-Item -Path $attachmentpath1).Name

$attachmentpath2 = "./filteredDiskReport.html"
$attachmentmessage2 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($attachmentpath2))
$attachmentname2 = (Get-Item -Path $attachmentpath2).Name

$attachmentpath3 = "./doubleFilteredDiskReport.html"
$attachmentmessage3 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($attachmentpath3))
$attachmentname3 = (Get-Item -Path $attachmentpath3).Name

$params = @{
    Message = @{
        Subject = $Subject
        Body = @{
            ContentType = "Text"
            Content = "Find attached Disk Reports"
        }
        ToRecipients = @(
            @{
                EmailAddress = @{
                    Address = $ToAddress
                }
            }
        )
        Attachments = @(
			@{
				"@odata.type" = "#microsoft.graph.fileAttachment"
				Name = $attachmentname1
				ContentType = "text/html"
				ContentBytes = $attachmentmessage1
			}
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
				Name = $attachmentname2
				ContentType = "text/html"
				ContentBytes = $attachmentmessage2
            }
            @{
                "@odata.type" = "#microsoft.graph.fileAttachment"
				Name = $attachmentname3
				ContentType = "text/html"
				ContentBytes = $attachmentmessage3
            }
		)
    }
    SaveToSentItems = "false"
}

Send-MgUserMail -UserId $MgUserID -BodyParameter $params
Disconnect-MgGraph
