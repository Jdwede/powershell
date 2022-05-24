function Check-IsElevated
{
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-Not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Host -ForegroundColor Red "Script must be launched as administrator. Close this window and try again."
        Write-Host -NoNewLine 'Press any key to exit ...';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        Exit
    }
}

function Get-Win32Apps
{
    Write-Host "Getting Win32 apps ... " -NoNewline
    Get-WmiObject -Class Win32_Product | Select Name, Version | Out-File $PSScriptRoot\win32_apps.txt
    if($?) { Write-Host -ForegroundColor Green "success." } else { Write-Host -ForegroundColor Red "failed." }
}

function Get-UwpApps
{
    Write-Host "Getting UWP apps ... " -NoNewline
    Get-AppxPackage –AllUsers | Select Name, Version | Out-File $PSScriptRoot\uwp_apps.txt
    if($?) { Write-Host -ForegroundColor Green "success." } else { Write-Host -ForegroundColor Red "failed." }
}

# Elevation required to get UWP apps
Check-IsElevated
Get-Win32Apps
Get-UwpApps
