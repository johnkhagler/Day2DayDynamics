function Start-AXMSBuildImport{
#############################################################################################################################################################################################################################################
#.Synopsis
#  Imports Visual Studio projects for a specific environment.
#.Example
#  Start-AXMSBuildImport -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -MSBuildPath 'C:\Windows\Microsoft.NET\Framework\v4.0.30319' -ProjectFile 'C:\ImportVSProject' -Layer 'var' -LayerCode 'uerl3958738493' -ModelName 'D2D Model'
#.Example
#  Start-AXMSBuildImport -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1' -Layer 'var' -LayerCode 'uerl3958738493' -ModelName 'D2D Model'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter MSBuildPath
#  The path to msbuild.exe.
#.Parameter $ImportVSProjectsFile
#  The location of the ImportVSProjects.proj file.
#.Parameter ModelFileFolder
#  The path to msbuild.exe.
#.Parameter $Layer
#  The layer to import into.
#.Parameter $LayerCode
#  The development code for the specific layer.
#.Parameter $ModelName
#  The model to import into.
#.Parameter $BuildLogFolder
#  The folder to create the log files in.  Defaults to $env:TEMP
#.Parameter $DetailedSummary
#  Adds a detailed summary to the log file.
#.Parameter $Verbosity
#  Increases the level of log activity. Values = q[uiet], m[inimal], n[ormal], d[etailed], and diag[nostic]
#.Parameter Timeout
#  The amount of time in minutes before the process times out.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  The AX Version you are running the function against.
#.Parameter VariablePath
# The file location of a script to default parameters used.
##############################################################################################################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline = $True)]
        [String]$MSBuildPath,
        [Parameter(ValueFromPipeline = $True)]
        [String]$ImportVSProjectsFile,
        [Parameter(ValueFromPipeline = $True)]
        [String]$ModelFileFolder,
        [Parameter(ValueFromPipeline = $True)]
        [String]$Layer,
        [Parameter(ValueFromPipeline = $True)]
        [String]$LayerCode,
        [Parameter(ValueFromPipeline = $True)]
        [String]$ModelName,
        [Parameter(ValueFromPipeline = $True)]
        [String]$BuildLogFolder = $env:TEMP,
        [Parameter(ValueFromPipeline = $True)]
        [Switch]$DetailedSummary,
        [Parameter(ValueFromPipeline = $True)]
        [String]$Verbosity = '',
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 30,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [Net.Mail.MailMessage]$MailMsg,
        [Parameter(ValueFromPipeline = $True)]
        [String]$VariablePath = ''

    )
    #endregion

    $StartTime = Get-Date
    Write-Host ('Importing Visual Studio Projects : {0}' -f $StartTime) -ForegroundColor Black -BackgroundColor White

    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {   
        $VSBuildLogFile = Join-Path $BuildLogFolder ('VSImport.{0}.log' -f $ModelName.Replace(' ', ''))
        $VSErrorLogFile = Join-Path $BuildLogFolder ('VSImportError.{0}.log' -f $ModelName.Replace(' ', ''))
        $VSWarningLogFile = Join-Path $BuildLogFolder ('VSImportWarning.{0}.log' -f $ModelName.Replace(' ', ''))
        $Arguments =  '"{0}" /p:srcFolder="{1}" /p:axLayer={2} /p:axAolCode={3} /p:ModelName="{4}" /p:Configuration=Release /l:FileLogger,Microsoft.Build.Engine;logfile="{5}" /flp1:errorsonly;logfile="{6}" /flp2:WarningsOnly;logfile="{7}"' -f $ImportVSProjectsFile, $ModelFileFolder, $Layer, $LayerCode, $ModelName, $VSBuildLogFile, $VSErrorLogFile, $VSWarningLogFile
        
        if ($DetailedSummary)
        {
            $Arguments = $Arguments + ' /ds'
        }

        if ($Verbosity -ne '')
        {
            $Arguments = $Arguments + ' /v:{0}' -f $Verbosity
        }
        
        $Process = Start-Process msbuild.exe -WorkingDirectory $MSBuildPath -PassThru -WindowStyle minimized -ArgumentList $Arguments -Verbose

        if ($Process.WaitForExit(60000*$Timeout) -eq $false)
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('Importing Visual Studio projects failed : {0}' -f (Get-Date))
                $MailMsg.Body = ('Visual Studio projects import did not complete in {0} minutes.' -f $Timeout)
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
            }

            $Process.Kill()
            Throw ('Error: Visual Studio projects import did not complete in {0} minutes.' -f $Timeout)
        }
        else
        {
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('Compiling Visual Studio project complete. {0} - {1}' -f $StartTime, (Get-Date))
                $MailMsg.Body = 'See attached.'
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority -FileLocation $VSBuildLogFile
            }

            Write-Host ('Importing Visual Studio project complete. {0} - {1}' -f $StartTime, (Get-Date)) -ForegroundColor Black -BackgroundColor White
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
