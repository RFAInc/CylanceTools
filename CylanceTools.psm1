function Get-CylanceRegistration {
    [CmdletBinding()]
    [OutputType([string])]
    param(
    )

    Begin {
        $RegPath = "HKLM:\SOFTWARE\Cylance\Desktop"
    }

    Process {
        try {
            (Get-ItemProperty -LiteralPath $RegPath -Name 'InstallToken' -ea 0).InstallToken
        } catch { 
            Write-Warning 'InstallToken was not found!'
        }
    }
}

function Test-CylanceRegistration {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Install Token for Cylance
        [Parameter(Mandatory=$true)]
        [string]$Key
    )

    Begin {
        $RegPath = "HKLM:\SOFTWARE\Cylance\Desktop"
    }

    Process {
        $InstallToken = $Key.Trim()

        try {
            (Get-ItemProperty -LiteralPath $RegPath -Name 'InstallToken' -ea 0).InstallToken -eq $InstallToken
        } catch { $false }
    }
}

function Set-CylanceRegistration
{
    [CmdletBinding()]
    param(
        # Install Token for Cylance
        [Parameter(Mandatory=$true)]
        [string]$Key
    )

    Begin {
        $RegPath = "HKLM:\SOFTWARE\Cylance\Desktop"
    }

    Process {
        $InstallToken = $Key.Trim()

        try {
            New-ItemProperty -LiteralPath $RegPath -Name 'InstallToken' -Value $InstallToken -PropertyType String -Force -ea 0
        } catch {
            Try {
                Set-ItemProperty -LiteralPath $RegPath -Name 'InstallToken' -Value $InstallToken -PropertyType String -Force -ea 0
            } Catch {
                throw 'InstallToken could not be set!'
            }
        }
    }
}

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

        # Load some external functions
        $web = New-Object Net.WebClient
        $TheseFunctionsForPstFileInfo = @(
            'https://raw.githubusercontent.com/tonypags/PsWinAdmin/master/Get-InstalledSoftware.ps1'
        )
        Foreach ($uri in $TheseFunctionsForPstFileInfo) {
            $web.DownloadString($uri) | Invoke-Expression
        }
        $web.Dispose | Out-Null

        # Define cases
        $Cases = @(
            [pscustomobject]@{
                Case = 1
                Pattern = $null
                Like = 'MsiExec.exe /X{*'
                Replacement = '{0} /qn /norestart /log "c:\windows\temp\cylance-remove.log"'
            }
            [pscustomobject]@{
                Case = 2
                Pattern = '\s\/modify'
                Like = $null
                Replacement = ' /uninstall'
            }
            [pscustomobject]@{
                Case = 3
                Pattern = $null
                Like = '*.exe"* /uninstall'
                Replacement = $null
            }
        )#END $Cases

        # Get uninstall string for Cylance
        $strUninstall = Get-InstalledSoftware |
            Where-Object {$_.Name -like 'Cylance*'} |
            Select-Object -ExpandProperty UninstallCommand
        Write-Debug "found $($strUninstall)"
    }
    
    process {
        
    }
    
    end {
        
        # Test to see which case
        $foundCase = $null
        foreach ($Case in $Cases) {
            $thisCase = $Case.Case
            if ($strUninstall -match ($Case.Pattern) -and ($Case.Pattern)) {
                Write-Debug "match case"
                $foundCase = $thisCase
                continue
            } elseif ($strUninstall -like ($Case.Like) -and ($Case.Like)) {
                Write-Debug "like case"
                $foundCase = $thisCase
                continue
            }
        }#END foreach ($Case in $Cases)

        # Isolate my case
        $objCase = $Cases | Where-Object {$_.Case -eq $foundCase}

        switch ($foundCase) {
            1 {
                # Take existing string and append to it
                $strFinalString = ($objCase.Replacement) -f ($strUninstall)
            }
            2 {
                # Replace case pattern with replacement
                $strFinalString = $strUninstall -replace ($objCase.Pattern), ($objCase.Replacement)
            }
            3 {
                # This case requires no modification
                $strFinalString = $strUninstall
            }
            Default {throw 'unhandled case'}
        }#END switch ($foundCase)

        # Execute uninstaller string
        Write-Verbose $strFinalString
        Write-Debug "final string ready"
        & { $strFinalString }

    }#END end
}
