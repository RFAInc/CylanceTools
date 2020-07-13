# DRAFT


function Uninstall-Cylance {
    <#
    .SYNOPSIS
    Removes the application from the local system.
    .DESCRIPTION
    Searches the local registry for an uninstall string, classifies the string based on path or GUID, and executes a command with silent options.
    .NOTES
    Examples of actual uninstall strings found on devices:
    Logs of attempts are showing the following for the invoked:

    msiexec.exe /X "C:\ProgramData\Package Cache{0074de7b-882e-42ef-bf12-6da746eeb15f}\CylanceProtectSetup.exe" /modify

    This worked:

    "C:\ProgramData\Package Cache{0074de7b-882e-42ef-bf12-6da746eeb15f}\CylanceProtectSetup.exe" /uninstall
    #>
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        $Cases = @(
            [pscustomobject]@{
                Case = 1
                Pattern = '*+?ProgramData\\Package\sCache\{.+?\}\\CylanceProtectSetup\.exe.*'
                Replacement = '"C:\ProgramData\Package Cache{{{0}}}\CylanceProtectSetup.exe" /uninstall'
            }
        )
    }
    
    process {
        
    }
    
    end {
        
    }
}
