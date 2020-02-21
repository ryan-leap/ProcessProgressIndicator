function Start-ProcessProgressIndicator {
<#
.SYNOPSIS
  Starts a PowerShell instance which shows a Write-Progress indicator while a process is still running
.DESCRIPTION
  Useful for creating a foreground process that shows a progress meter for a running process.
.PARAMETER Id
  Specifies the process ID (PID) to monitor
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
        [string] $CurrentOperation,

        [ValidateSet('Normal', 'Maximized')]
        [Parameter(Mandatory=$false)]
        [string] $WindowStyle = 'Normal',

        [ValidateSet('Slow', 'Normal', 'Fast')]
        [Parameter(Mandatory=$false)]
        [string] $ProgressMeterSpeed = 'Normal',

        [Parameter(Mandatory=$false)]
        [int16] $SecondsToDisplayCompletionMessage = 10
    )
    
    switch -exact ($ProgressMeterSpeed) {
      'Slow'   { [int16] $progressPace = 1000 }
      'Normal' { [int16] $progressPace =  500 }
      'Fast'   { [int16] $progressPace =  100 }
      Default  { [int16] $progressPace =  500}
    }

    $hereBlock = @"
    Try {
        `$process = Get-Process -Id $Id -ErrorAction Stop
        `$Host.UI.RawUI.WindowTitle = "Waiting for `$(`$process.Name)"
        `$stopwatch =  [system.diagnostics.stopwatch]::StartNew()
        do {
            for (`$i = 1; `$i -le 100; `$i++) {
                `$elapsed = "{0,0:D2}:{1,0:D2}:{2,0:D2}" -f `$stopwatch.Elapsed.Hours,`$stopwatch.Elapsed.Minutes,`$stopwatch.Elapsed.Seconds
                Write-Progress -Activity "Waiting for process '`$(`$process.Name)' to complete..." -Status "Elapsed runtime (HH:MM:SS): `$elapsed" -CurrentOperation "$CurrentOperation..." -PercentComplete `$i
                Start-Sleep -Milliseconds $progressPace
                if (`$process.HasExited) {
                    Write-Progress -Activity "Process '`$(`$process.Name)' complete!" -Status "Elapsed runtime (HH:MM:SS): `$elapsed" -CurrentOperation "$CurrentOperation complete!" -PercentComplete 100
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