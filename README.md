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
