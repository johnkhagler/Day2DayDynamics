function Start-AXAutoRun{
###########################################################################################################################################################
#.Synopsis
#  Starts the AX Client with the AutoRun command.
#.Description
#  Starts the AX Client with the AutoRun command.
#.Example
#  Start-AXAutoRun -Ax $ax -XMLFile 'C:\AOTCompile.xml' -LogFile 'C:\Test.log' -Process 'AOT compile' -Timeout 480 -SMTPServer 'smtp.d2dynamics.com -MailMsg $MailMsg
#.Parameter Ax
#  The PSObject returned from Get-AXConfig holding AX environment parameters.
#.Parameter XMLFile
#  The path to the AutoRun XML file.
#.Parameter LogFile
#  The path to the log file.
#.Parameter Process
#  The AutoRun process.  Used for notifications.
#.Parameter Timeout
#  The timeout for the process.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
###########################################################################################################################################################
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [PSObject]$Ax,
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$XMLFile,
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$LogFile,
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()] 
    [String]$Process,
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [Int]$Timeout,    
    [Parameter(ValueFromPipeline = $True)] 
    [String]$SMTPServer,
    [Parameter(ValueFromPipeline = $True)]
    [Net.Mail.MailMessage]$MailMsg
)
    Write-Host ('Starting AX autorun process - {0} : {1}' -f $Process, (Get-Date)) -ForegroundColor Black -BackgroundColor White
    $StartTime = Get-Date

    try
    {
        $ArgumentList = '"{0}" -development -internal=noModalBoxes -StartupCmd=autorun_{1}"' -f $Ax.FilePath, $XmlFile
        $axProcess = Start-Process ax32.exe -WorkingDirectory $ax.ClientBinDir -PassThru -WindowStyle minimized -ArgumentList $ArgumentList -OutVariable out

        if ($axProcess.WaitForExit(60000*$Timeout) -eq $false)
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('{0} process failed on {1} : {2}' -f $Process, $Ax.AosComputerName, (Get-Date))
                $MailMsg.Body = ('{0} process did not complete in {1} minutes.' -f $Process, $Timeout)
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
            }

            $axProcess.Kill()
            Throw ('Error: {0} process on {1} did not complete within {2} minutes' -f $Process, $ax.AosComputerName, $Timeout)
        }
        else
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('{0} - {1} complete: {2} - {3}' -f $ax.AosComputerName, $Process, $StartTime, (Get-Date))
                $MailMsg.Body = 'See attached.'
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority -FileLocation $LogFile
            }

            Write-Host ('AX autorun process complete - {0} : {1}' -f $Process, (Get-Date)) -ForegroundColor Black -BackgroundColor White
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}