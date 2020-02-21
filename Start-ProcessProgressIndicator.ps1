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
.PARAMETER CurrentOperation
  Specifies the line of text below the progress bar. This text describes the operation that is currently taking
  place
.PARAMETER ProgressMeterSpeed
  Controls the speed at which the progress bar increments
.PARAMETER SecondsToDisplayCompletionMessage
  When the process completes the message will briefly change indicating operation is complete.  This parameter
  governs how long that message will be displayed.
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
        [string] $CurrentOperation,

        [ValidateSet('Normal', 'Hidden', 'Minimized', 'Maximized')]
        [Parameter(Mandatory=$false)]
        [string] $WindowStyle = 'Maximized',

        [ValidateSet('Slow', 'Medium', 'Fast')]
        [Parameter(Mandatory=$false)]
        [string] $ProgressMeterSpeed = 'Medium',

        [int16] $SecondsToDisplayCompletionMessage = 15
    )
    
    switch -exact ($ProgressMeterSpeed) {
      'Slow'   { [int16] $progressDelay = 1000 }
      'Medium' { [int16] $progressDelay =  500 }
      'Fast'   { [int16] $progressDelay =  100 }
      Default  { [int16] $progressDelay =  500}
    }

    $hereBlock = @"
    Try {
        `$Host.UI.RawUI.WindowTitle = "$Activity"
        `$process = Get-Process -Id $Id -ErrorAction Stop
        `$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
        do {
            for (`$i = 1; `$i -le 100; `$i++) {
                `$elapsed = "{0,0:D2}:{1,0:D2}:{2,0:D2}" -f `$stopwatch.Elapsed.Hours,`$stopwatch.Elapsed.Minutes,`$stopwatch.Elapsed.Seconds
                Write-Progress -Activity "$Activity" -Status "$Status..." -CurrentOperation "`$elapsed $CurrentOperation..." -PercentComplete `$i
                Start-Sleep -Milliseconds $progressDelay
                if (`$process.HasExited) {
                    Write-Progress -Activity "$Activity" -Status "$Status complete." -CurrentOperation "`$elapsed $CurrentOperation complete." -PercentComplete 100
                    Start-Sleep -Seconds $SecondsToDisplayCompletionMessage
                    break
                }
            }
      } while (-not(`$process.HasExited))
    }
    Catch {
      Write-Warning "Unable to track progress of process with ID [$Id]."
      Start-Sleep -Seconds $SecondsToDisplayCompletionMessage
    }
"@

    [string] $encodedCommand = [convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($hereBlock))
    $processArgs = @('-NoLogo','-NoProfile','-NonInteractive','-EncodedCommand',$encodedCommand)
    Start-Process 'powershell.exe' -ArgumentList $processArgs -WindowStyle $WindowStyle

}