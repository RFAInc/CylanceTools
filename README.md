# CylanceTools
Tools for management of CylancePROTECT for Windows

## Example: Change the Installer Token on a device.
Define a key, ensure it is set on the device, then return the active key string.
```
$Key = '1234567890ABCDEFG'
$IsMatchingKey = Test-CylanceRegistration -Key $Key

if (!$IsMatchingKey) {
    Set-CylanceRegistration -Key $Key | Out-Null
}

Get-CylanceRegistration
```
## Example: Uninstall Cylance
```
(New-Object Net.Webclient).DownloadString('https://raw.githubusercontent.com/RFAInc/CylanceTools/master/CylanceTools.psm1') | iex; Uninstall-Cylance -Verbose
```


# Registry Info for Manual Troubleshooting
We may want to add some checks for these artifacts to the test script, 
To ensure Cylance has been removed from all locations:

 

Remove Cylance folders from C:\Program Files\, %ProgramData%, and %AppData%\Local

 

Remove the Cylance driver from C:\Windows\system32\drivers and C:\Windows\system32\drvstore

 

Remove Cylance registry keys from HKLM\Software and HKLM\System\CurrentControlSet\services

 

You may also need to remove: HKEY_CLASSES_ROOT\Installer\Products\C5CF46E2682913A419B6D0A84E2B9245

 

<Comprehensive list>

 

C:\Program Files\Cylance

C:\ProgramData\Cylance

C:\Windows\System32\drivers\CyOpticsDrv.bak

C:\Windows\System32\drivers\CyOpticsDrv.sys

C:\Windows\System32\drivers\CyProtectDrv64.sys

C:\Windows\System32\DrvStore\CyOpticsDr_93D37CBD237A3B772B26BAC98F74A83C7DB67130

C:\Windows\System32\DrvStore\CyProtectD_35DEA6E5F703DD2A525FF0BF84B2520B9A03E8BC

 

HKEY_CLASSES_ROOT\Installer\Products\C5CF46E2682913A419B6D0A84E2B9245

HKEY_LOCAL_MACHINE\SOFTWARE\Cylance

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\CyProtectDrv

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\CyOpticsDrv

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\CyOptics

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\CylanceSvc
