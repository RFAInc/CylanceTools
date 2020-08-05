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

function Test-CylanceInstall {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
    )

    Begin {
        $knownRegPath = "HKLM:\SOFTWARE\Cylance\Desktop"
        $knownExePath = Join-Path $env:ProgramFiles "Cylance\Desktop\cyprotect.exe"
        $Service = Get-Service -Name Cy*
        $Process = Get-Process cyprotect -ea 0
        $IsInstalled = $false
    }

    Process {
        
        # Find the process and test its EXE against the known EXE path.
        if ($Process) {
            $IsInstalled =$true
        } else {
            Write-Verbose "No Process exists."
        }

        # Find the service and test its EXE against the known EXE path.
        if ($Service.count -eq 1) {

            $thisExePath = (
                Get-WmiObject win32_Service |
                    Where-Object {
                        $_.Name -eq ($Service.Name)
                    }
            ).PathName.Trim('"')

            if ($knownExePath -eq $thisExePath) {
                $IsInstalled =$true
            }

        } elseif ($Service.count -gt 1) {
            
            # loop thru
            foreach ($svc in $Service) {
                
                $thisExePath = (
                    Get-WmiObject win32_Service |
                        Where-Object {
                            $_.Name -eq ($Service.Name)
                        }
                ).PathName.Trim('"')
                
                if ($knownExePath -eq $thisExePath) {
                    $IsInstalled =$true
                }

            }

        } else {
            Write-Verbose "No Service exists."
        }

        # Do some simple path checks
        if (Get-Item $knownExePath -ea 0) {
            $IsInstalled =$true
        } else {
            Write-Verbose "No Path to EXE exists."
        }

        if (Get-Item $knownRegPath -ea 0) {
            $IsInstalled =$true
        } else {
            Write-Verbose "No Registry path exists."
        }
    }

    End {
        
        Write-Output $IsInstalled

    }
}

function Get-CylanceUninstallString {
    <#
    .SYNOPSIS
    Helps to silently remove the application from the local system.
    .DESCRIPTION
    Searches the local registry for an uninstall string, classifies the string based on path or GUID, and returns a command with silent options.
    .NOTES
    Examples of actual uninstall strings found on devices:
    Logs of attempts are showing the following for the invoked:

    msiexec.exe /X "C:\ProgramData\Package Cache{0074de7b-882e-42ef-bf12-6da746eeb15f}\CylanceProtectSetup.exe" /modify

    This worked:

    "C:\ProgramData\Package Cache{0074de7b-882e-42ef-bf12-6da746eeb15f}\CylanceProtectSetup.exe" /uninstall
    #>
    [CmdletBinding()]
    param (
        # Path to log file for MSI case only
        [Parameter()]
        [string]
        $LogPath = 'c:\windows\temp\cylance-remove.log'
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
                Replacement = 'msiexec /X "{{{0}}}" /qn /norestart /log "{1}"'
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
                # Extract the GUId from the uninstall string
                $ptnGuid = '([A-Z0-9]{8}-([A-Z0-9]{4}-){3}[A-Z0-9]{12})'
                $guid = [regex]::Match($strUninstall,$ptnGuid).Groups[1].Value

                # Rebuild the uninstall string from guid and append log path to it
                [string]$strFinalString = (($objCase.Replacement) -f ($guid), ($LogPath))
            }
            2 {
                # Replace case pattern with replacement
                [string]$strFinalString = $strUninstall -replace ($objCase.Pattern), ($objCase.Replacement)
            }
            3 {
                # This case requires no modification
                [string]$strFinalString = $strUninstall
            }
            Default {throw 'unhandled case'}
        }#END switch ($foundCase)

        Write-Output $strFinalString
        
    }#END end
}

function Uninstall-Cylance {
    <#
    .SYNOPSIS
    Removes the application from the local system.
    .DESCRIPTION
    Searches the local registry for an uninstall string,
    classifies the string based on path or GUID, and executes
    a command with silent options and optional verbose output.
    #>
    [CmdletBinding()]
    
    $strUninstall = Get-CylanceUninstallString

    # Execute uninstaller string
    Write-Verbose $strUninstall
    Write-Debug "final string ready: `$strUninstall"
    Try {
        
        $origErrorActionPreference = $ErrorActionPreference
        Write-Verbose [string]('Attempting Command (1): ' + $strUninstall)
        Invoke-Expression $strUninstall -ea Stop

    } Catch {

        Try {
            $ErrorActionPreference = 'Stop'
            $sbUninstall = [scriptblock]::Create($strUninstall)
            Write-Verbose [string]('Attempting Command (2): ' + $strUninstall)
            & $sbUninstall
        } Catch {
            $ErrorActionPreference = 'SilentlyContinue'
            [string]$strFinalString = '& ' + $strUninstall
            $sbUninstall = [scriptblock]::Create($strFinalString)
            Write-Verbose [string]('Attempting Command (3): ' + $strUninstall)
            & $sbUninstall
        }

    } Finally {
        $ErrorActionPreference = $origErrorActionPreference
    }

    # Check the installer finished OK
    Start-Sleep -Seconds 15
    if (Test-CylanceInstall) {
        throw "Cylance failed to remove from $($env:COMPUTERNAME)!"
        Write-Verbose ($Error.Exception.Message)
    } else {
        Write-Verbose "Cylance successfully removed from $($env:COMPUTERNAME)."
    }

}

function Receive-RfaCylanceMsi {

    <#
    .SYNOPSIS
    Downloads the MSI installer for Cylance.
    .DESCRIPTION
    Uses the known location of the latest version of the Cylance MSI installer and downloads it to LabTech's package folder.
    .PARAMETER OsBitness
    Bitness of the OS
    .PARAMETER Path
    Target path for the download, not including filename
    #>
    [CmdletBinding()]

    param(
        # Bitness of the OS
        [Parameter()]
        [ValidateSet(32,64)]
        [int16]
        $OsBitness = 64,

        # Target path for the download, not including filename
        [Parameter()]
        [string]
        $Path = 'C:\Windows\LtSvc\packages\Cylance'
    )

    $Uri = switch ($OsBitness) {
        64 {'https://automate.rfa.com/LabTech/Transfer/Software/Cylance/CylanceProtect_x64.msi'}
        32 {'https://automate.rfa.com/LabTech/Transfer/Software/Cylance/CylanceProtect_x86.msi'}
        Default {throw 'unhandled OS Bitness value'}
    }

    # Grab the filename from the download URI
    $Filename = Split-Path $Uri -Leaf

    # Ensure the folder for the download exists
    if (Test-Path $Path) {} else {
        New-Item -Path $Path -ItemType Directory -Force
    }

    # Download the file
    $FullName = Join-Path $Path $Filename
    (New-Object Net.WebClient).DownloadFile($Uri,$FullName)

    # Return the resultant file object
    Get-Item $FullName

}
