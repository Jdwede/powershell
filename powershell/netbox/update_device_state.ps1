# This scripts retrieves a list of all workstations from netbox,
# pings those workstations, and those not responding to ping will have their status changed to "offline"
# Configure to run on a schedule

# api info
$api_root = "https://<NETBOX_DOMAIN_NAME>/api"
$token = "<API_TOKEN>"

# api headers
$headers = @{
	Authorization = "Token $token"
	Accept = "application/json"
}

# Return all netbox devices with the role of workstation as object array
function Get-NetboxWorkstations($api_root, $headers)
{
    $url = "$($api_root)/dcim/devices/?role=workstation&format=json&limit=100000&brief=1"
    $res = (Invoke-RestMethod -Uri $url -ContentType 'application/json' -Headers $headers -DisableKeepAlive -UseBasicParsing)
    $jsonObj = $res.results | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    return $jsonObj
}

# Ping all workstations, return workstations object array with added PingResult property
function Ping-Workstations($workstations)
{
    Write-Host "Pinging workstations ... " -NoNewline
    foreach($workstation in $workstations)
    {
        $workstation | Add-Member -NotePropertyName PingResult -NotePropertyValue Failed
        if(([System.Net.NetworkInformation.Ping]::new().SendPingAsync($workstation.name)).Result.Status -eq "Success")
        {
            $workstation.PingResult = "Success"
        }
    }
    Write-Host -ForegroundColor Green "OK"
    return $workstations
}

# Update the active/inactive status of workstations on netbox depending on their PingResult
function Update-NetboxWorkstationStatus($workstations, $headers)
{
    Write-Host "Updating netbox workstation status:"
    foreach($workstation in $workstations)
    {
        if($workstation.PingResult -eq "Success")
        {
            Write-Host "[ " -NoNewline
            Write-Host -ForegroundColor Green "OK" -NoNewline
            Write-Host " ] " -NoNewline
            Write-Host "Updating $($workstation.name) to " -NoNewline
            Write-Host -ForegroundColor Green "Online."
            $device = @{
                status = "active"
            }
        }
        else
        {
            Write-Host "[ " -NoNewline
            Write-Host -ForegroundColor Green "OK" -NoNewline
            Write-Host " ] " -NoNewline
            Write-Host "Updating $($workstation.name) to " -NoNewline
            Write-Host -ForegroundColor Red "Offline."
            $device = @{
                status = "offline"
            }
        }
        $deviceJson = $device | ConvertTo-Json -Depth 20
        $set = Invoke-RestMethod -Uri $workstation.url -Method Patch -ContentType 'application/json' -Headers $headers -Body $deviceJson -DisableKeepAlive -UseBasicParsing
    }
}

Update-NetboxWorkstationStatus (Ping-Workstations(Get-NetboxWorkstations $api_root $headers)) $headers
