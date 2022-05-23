# This script searches AD for a user and returns all locations where they are logged in

param (
	[string]$user
)
# Supress error messages
$ErrorActionPreference = "SilentlyContinue"

# Call Get-Username function
while([string]::IsNullOrEmpty($user)) {
	$user = Read-Host "`nEnter username (or last name) you want to search for"
}

Write-Host ""
if ((Get-ADUser $user) -eq $null) {
	Write-Host -ForegroundColor Red "Username [$user] not found on domain, please retry.`n"
	exit 1
}
Write-Host -ForegroundColor Green "[$user] was found on the domain. Searching...`n"

# Get list of computers from active directory and filter by hostname
$ComputerList = Get-ADComputer -Filter * -SearchBase "<LDAP_SEARCH_QUERY>" | Select-Object -ExpandProperty Name

# Get total number of computers
$numOfComputers = $ComputerList.Count
Write-Host -ForegroundColor Cyan -NoNewline "$numOfComputers "
Write-Host "total computers found on the domain."

# Asynchronously ping all computers in ComputerList, wait until all pings are completed
$Ping = forEach ($computer in $ComputerList)
{
    (New-Object System.Net.NetworkInformation.Ping).SendPingAsync($computer)
}
[Threading.Tasks.Task]::WaitAll($Ping)

# Convert IPs into Hostnames where ping is successful, then output results to a string
$successfulPingHostnameList = $Ping.Result | Where-Object {$_.Status -eq "Success"} | Select-Object @{Name="HostName";
Expression={
    try 
    {
        [System.Net.Dns]::GetHostEntry($_.Address).HostName
    }
    catch 
    {
        [string]::Empty
    }
}} | Format-Table -HideTableHeaders | Out-String -Stream | Where {$_} | foreach {$_.TrimEnd()}

# Remove domain at end of hostname for better readability
$successfulPingHostnameList = $successfulPingHostnameList -replace ".AD.EXAMPLE.COM", ""
$successfulPingHostnameList = $successfulPingHostnameList -replace ".AD.EXAMPLE...", ""

# Store the number of computers that respond to ping
$numOfRespondingComputers = $successfulPingHostnameList.Count

Write-Host -ForegroundColor Cyan -NoNewline "$numOfRespondingComputers " 
Write-Host "computers are responding to ping.`n"
Write-Host "Scanning computers for the user, one moment...."

# Counter to see if processOwner was found. If it stays at 0, no match was found.
$ownerComputerList = New-Object System.Collections.ArrayList

# Once successful pings are finished, loop through successful ping computers to find owner of explorer.exe
foreach ($comp in $successfulPingHostnameList)
{
    #Write-Host -Foregroundcolor Green "Ping Success on $comp."

    # Get explorer.exe process
    # Note: You must run powershell as an administrator in order to properly obtain explorer.exe over other computers
    $explorerProcess = Get-WmiObject win32_process -ErrorAction SilentlyContinue -ComputerName $comp -Filter "Name = 'explorer.exe'" -AsJob | Wait-Job -Timeout 1 | Receive-Job

    <#
    # If explorerProcess is null, no one is logged in 
    if (!($explorerProcess))
    {
        Write-Host -ForegroundColor Red "No one is logged in on $comp."
    }
    #>

    # Iterate through the explorer.exe process on each computer in the successful ping list
    foreach ($process in $explorerProcess)
    {
        $processOwner = ($process.GetOwner()).User

        if ($processOwner -like "*$user*")
        {
			if(!$ownerComputerList.Contains($comp))
			{
				Write-Verbose "$user found on $comp."
				[void]$ownerComputerList.Add($comp)
			}
        }
        else
        {
            Write-Verbose "$processOwner is logged in on $comp."         
        }
    }
}

# Case for when user is found on domain, but is not logged on anywhere
if ($ownerComputerList.Count -eq 0)
{
    Write-Host -ForegroundColor Yellow "`n$user was found on the domain, but is not logged in anywhere."    
}
# Display results when computer and user are found
else
{
    Write-Host "[$user] was found on the following computer(s):"
	($ownerComputerList -join "`n")
}

Write-Host ""
Write-Host "Search complete."

Read-Host -Prompt "Press any key to continue"
