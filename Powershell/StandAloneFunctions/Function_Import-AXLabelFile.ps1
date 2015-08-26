function Import-AXLabelFile{
###########################################################################################################################################################
#.Synopsis
#  Imports a label file into a specific environment.
#.Description
#  Imports a label file into a specific environment.
#.Example
#  Import-AXLabelFile -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LableFile 'C:\axD2Den-us.ald'
#.Example
#  Import-AXLabelFile -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1' -LableFile 'C:\axD2Den-us.ald' -Model 'D2D Model'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter Model
#  The Model to work in, in AX.
#.Parameter LabelFile
#  The label file to import.
#.Parameter Timeout
#  The amount of time in minutes before the process times out.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter AXVersion
#  The AX Version you are running the function against.
#.Parameter VariablePath
# The file location of a script to default parameters used.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline = $True)]
        [String]$Model,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$LabelFile,
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 10,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [Net.Mail.MailMessage]$MailMsg,
        [Parameter(ValueFromPipeline = $True)]
        [Int]$AXVersion = 6,
        [Parameter(ValueFromPipeline = $True)]
        [String]$VariablePath = ''

    )
    #endregion
        
    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    if (!(Test-Path $LabelFile))
    {
        Throw 'Error: Unable to find label file'
    }

    try
    {  
        if ($Model)
        {
            $Model = '"-model={0}"' -f $Model
        }
        else
        {
            $Model = ''
        }
         
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        Write-Host ('Importing label file : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
        $ArgumentList = '"{0}" -development -internal=noModalBoxes "-startupcmd=aldimport_{1}" {2}' -f $Ax.FilePath, $LabelFile, $Model
        $axProcess = Start-Process ax32.exe -WorkingDirectory $ax.ClientBinDir -PassThru -WindowStyle minimized -ArgumentList $ArgumentList -OutVariable out

        if ($axProcess.WaitForExit(60000*$Timeout) -eq $false)
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('Label file import failed on {0} : {1}' -f $Ax.AosComputerName, (Get-Date))
                $MailMsg.Body = ('Label file import did not complete in {0} minutes : {1}' -f $Timeout, $LabelFile)
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
            }

            $axProcess.Kill()
            Throw ('Error: Label file import on {0} did not complete within {1} minutes : {2}' -f $ax.AosComputerName, $Timeout, $LabelFile)
        }
        else
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('{0} - Label file import complete: {1} - {2}' -f $ax.AosComputerName, $StartTime, (Get-Date))
                $MailMsg.Body = 'See attached.'
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority -FileLocation $LabelFile
            }

            Write-Host ('Label file import complete - {0} : {1}' -f $LabelFile, (Get-Date)) -ForegroundColor Black -BackgroundColor White
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
