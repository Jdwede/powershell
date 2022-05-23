# RemoteApp webfeed URL
$url = "https://<FQDN>/rdweb/feed/webfeed.aspx"

# Construct the XML file
$XML = @"
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<workspace name="<WORKSPACE_NAME>" xmlns="http://schemas.microsoft.com/ts/2008/09/tswcx" xmlns:xs="http://www.w3.org/2001/XMLSchema">
<defaultFeed url="$URL"/>
</workspace>
"@

# WCX file path
$Directory = "c:\webfeed\"
$WCX = "webfeed.wcx";
$FullPath = ($Directory + $WCX);
New-Item $Directory -Type Directory -Force | Out-Null;
$XML | Out-File -FilePath $FullPath -Encoding utf8 -Force | Out-Null;

# Add the web feed
Start-Process -FilePath rundll32.exe -ArgumentList 'tsworkspace,WorkspaceSilentSetup',$($FullPath).ToString() -Wait -NoNewWindow;
