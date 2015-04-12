function Sync-AXDB{
###########################################################################################################################################################
#.Synopsis
#  Synchronizes the DataDictionary for a specific environment.
#.Description
#  Synchronizes the DataDictionary for a specific environment.
#.Example
#  Sync-AXDB -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LogFile 'C:\TestLog.log' -Timeout 90
#.Example
#  Sync-AXDB -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter LogFile
#  The path to the log file.
#.Parameter Timeout
#  The amount of time in minutes before the process times out.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter AXVersion
#  The AX Version you are running the function against.
#.Parameter VariablePath
# The file location of a script to default parameters used
###########################################################################################################################################################
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $True)]
    [String]$ConfigPath,
    [Parameter(ValueFromPipeline = $True)]
    [String]$LogFile = (Join-Path $env:TEMP 'DBSync.log'),
    [Parameter(ValueFromPipeline = $True)]
    [Int]$Timeout = 120,
    [Parameter(ValueFromPipeline = $True)] 
    [String]$SMTPServer,
    [Parameter(ValueFromPipeline = $True)]
    [Net.Mail.MailMessage]$MailMsg,
    [Parameter(ValueFromPipeline = $True)]
    [Int]$AXVersion = 6,
    [Parameter(ValueFromPipeline = $True)]
    [String]$VariablePath = '?'
)
    Import-Module DynamicsAXCommunity -DisableNameChecking

    if (Test-Path $VariablePath)
    {
        ."$VariablePath"
    }

    try
    {   
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $XML = Get-AXAutoRunXML -Command 'Synchronize' -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_DBSync'))           
        New-Item $XmlFile -type file -force -value $XML

        Write-Host ('Starting AX autorun process - DB Synchronize : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
        $StartTime = Get-Date

        $ArgumentList = '"{0}" -development -internal=noModalBoxes -StartupCmd=autorun_{1}"' -f $ax.FilePath, $XmlFile
        $axProcess = Start-Process ax32.exe -WorkingDirectory $ax.ClientBinDir -PassThru -WindowStyle minimized -ArgumentList $ArgumentList -OutVariable out

        if ($axProcess.WaitForExit(60000*$Timeout) -eq $false)
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('DB synchronize process failed on {0} : {1}' -f $ax.AosComputerName, (Get-Date))
                $MailMsg.Body = ('DB synchronize process did not complete in {0} minutes.' -f $Timeout)
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority -FileLocation $LogFile
            }

            $axProcess.Kill()
            Throw ('Error: DB synchronization process on {0} did not complete within {1} minutes' -f $ax.AosComputerName, $Timeout)
        }
        else
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('{0} - DB synchronize finished: {1} - {2}' -f $ax.AosComputerName, $StartTime, (Get-Date))
                $MailMsg.Body = 'See attached.'
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority -FileLocation $LogFile
            }

            Write-Host ('AX autorun process complete - DB Synchronize: {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}