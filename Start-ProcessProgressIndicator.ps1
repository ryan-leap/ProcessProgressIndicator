function Start-ProcessProgressIndicator {
<#
.SYNOPSIS
  Starts a PowerShell instance which shows a Write-Progress indicator while a process is still running
.DESCRIPTION
  Useful for creating a foreground process that shows a progress meter for a running process.
.PARAMETER Id
  Specifies the process ID (PID) to monitor
.PARAMETER Activity
  Specifies the first line of text in the heading above the status bar. This text describes the activity whose
  progress is being reported.
.PARAMETER Status
  Specifies the second line of text in the heading above the status bar. This text describes current state of
  the activity.
.PARAMETER StatusComplete
  Specifies the second line of text in the heading above the status bar. This text describes the state when
  the activity has completed.
.PARAMETER CurrentOperation
  Specifies the line of text below the progress bar. This text describes the operation that is currently taking
  place
.PARAMETER CurrentOperationComplete
  Specifies the line of text below the progress bar. This text describes the operation that has completed.
.PARAMETER WindowTitle
  Name to be displayed in the PowerShell Window Title
.PARAMETER WindowStyle
  Specifies the state of the window that is used for the new process. The acceptable values for this parameter
  are: Normal, Hidden, Minimized, and Maximized. The default value is Maximized.
.EXAMPLE
.NOTES
   Author: Ryan Leap
   Email: ryan.leap@gmail.com
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int32] $Id,

        [Parameter(Mandatory=$true)]
        [string] $Activity,

        [Parameter(Mandatory=$true)]
        [string] $Status,

        [Parameter(Mandatory=$true)]
        [string] $statusComplete,

        [Parameter(Mandatory=$true)]
        [string] $CurrentOperation,

        [Parameter(Mandatory=$true)]
        [string] $CurrentOperationComplete,

        [Parameter(Mandatory=$true)]
        [string] $WindowTitle,

        [ValidateSet('Normal', 'Hidden', 'Minimized', 'Maximized')]
        [Parameter(Mandatory=$false)]
        [string] $WindowStyle = 'Maximized'
    )
    
    $hereBlock = @"
    Try {
        `$Host.UI.RawUI.WindowTitle = "$WindowTitle"
        `$process = Get-Process -Id $Id -ErrorAction Stop
        if ($null -eq `$process) {
          Throw "Process not found!"
        }
        do {
            for (`$i = 1; `$i -le 100; `$i++) {
                Write-Progress -Activity "$Activity" -Status "$Status" -CurrentOperation "$CurrentOperation" -PercentComplete `$i
                Start-Sleep -Milliseconds 200
                if (`$process.HasExited) {
                    Write-Progress -Activity "$Activity" -Status "$StatusComplete" -CurrentOperation "$CurrentOperationComplete" -PercentComplete 100
                    Start-Sleep -Seconds 15
                    break
                }
            }
      } while (-not(`$process.HasExited))
    }
    Catch {
      Write-Warning "Unable to track progress of process with ID [$Id]."
      Start-Sleep -Seconds 10
    }
"@

    [string] $encodedCommand = [convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($hereBlock))
    $processArgs = @('-NoLogo','-NoProfile','-NonInteractive','-EncodedCommand',$encodedCommand)
    Start-Process 'powershell.exe' -ArgumentList $processArgs -WindowStyle $WindowStyle

}