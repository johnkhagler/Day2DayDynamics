# This PowerShell module was released under the Ms-PL license
# http://www.opensource.org/licenses/ms-pl.html
# This script was originally intended for use with Microsoft Dynamics AX 2012
# and maintained and distributed as a project on CodePlex
# https://day2daydynamics.codeplex.com/

# If you're using Powershell 2.0, you have to import the module before using.
# Please refer to Importing Modules: http://msdn.microsoft.com/en-us/library/dd878284%28v=vs.85%29.aspx for details.


#region Functions
function Get-AXAutoRunXML{
###########################################################################################################################################################
#.Synopsis
#  Creates an AxaptaAutoRun xml string.
#.Description
#  Creates an AxaptaAutoRun xml string.
#.Example
#  Get-AXAutoRunXML -$Command 'Synchronize'
#.Example
#  Get-AXAutoRunXML -$Command 'CompileApplication' -LogFile 'C:\TestLog.log' -ExitWhenDone
#.Parameter ExitWhenDone
#  Tells AX to close when the command is complete.
#.Parameter -LogFile
#  Tells AX whether to use a log file and where to put it.
#.Parameter -$Command
#  Tells AX what autorun command to use.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [Switch]$ExitWhenDone,
        [Parameter(ValueFromPipeline = $True)]
        [String]$LogFile,
        [Parameter(ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$Command
    )
    #endregion

    $XMLHeader = '<?xml version="1.0" encoding="utf-8"?>'
    $AutoRunHeader = '<AxaptaAutoRun version="4.0"{0}>'
    $AutoRunCommand = '<{0} />' -f $Command
    $AutoRunFooter = '</AxaptaAutoRun>'

    if (![String]::IsNullOrWhiteSpace($LogFile))
    {
       $ARHInsert += ' logFile="{0}"' -f $LogFile
    }

    if ($ExitWhenDone)
    {
       $ARHInsert += ' exitWhenDone="true"'
    }

    $XML = $XMLHeader + ($AutoRunHeader -f $ARHInsert) + $AutoRunCommand + $AutoRunFooter

    $XML.ToString()
}
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
#.Parameter Model
#  The Model to work in, in AX.
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
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [PSObject]$Ax,
        [Parameter(ValueFromPipeline = $True)]
        [String]$Model,
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
    #endregion

    Write-Host ('Starting AX autorun process - {0} : {1}' -f $Process, (Get-Date)) -ForegroundColor Black -BackgroundColor White
    $StartTime = Get-Date

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

        $ArgumentList = '"{0}" -development -internal=noModalBoxes "-StartupCmd=autorun_{1}" {2}' -f $Ax.FilePath, $XmlFile, $Model
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
function Start-AXBuildCompile{
#####################################################################################################################################################
#.Synopsis
#  Runs the AXBuild.exe compile on the AOS Server.
#.Description
#  Runs the AXBuild.exe compile on the AOS Server.  No parameters are required to allow the use of a variable default file.
#.Example
#  Start-AXBuildCompile -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -SMTPServer 'smtp.d2ddynamics.com' -MailMsg $MailMsg -Workers 4
#.Example
#  Start-AXBuildCompile -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1'
#.Parameter ConfigPath
#  A configuration for the AX environment to be compiled.  Must be run on the AOS server.
#.Parameter AXVersion
#  The AX Version you are running the function against.  Defaults to 6.  The function is only valid for AX 2012 R2 CU7 and above.
#.Parameter LogPath
#  Allows users to override the AxBuild.exe default log location.
#.Parameter NoCleanup
#  Stops AxBuild.exe from cleaning up temporary files.
#.Parameter Workers
#  The number of processes running the build.
#.Parameter StopAOS
#  Used to stop the AOS before running the compile.  The AOS is restarted if it was stopped by this function.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter VariablePath
# The file location of a script to default parameters used.
######################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline = $True)]
        [Int]$AXVersion = 6,
        [Parameter(ValueFromPipeline = $True)]
        [String]$LogPath = '',
        [Parameter(ValueFromPipeline = $True)]
        [Switch]$NoCleanup,
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Workers,
        [Parameter(ValueFromPipeline = $True)]
        [Switch]$StopAOS,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [Net.Mail.MailMessage]$MailMsg,
        [Parameter(ValueFromPipeline = $True)]
        [String]$VariablePath = ''
    )
    #endregion

    $StartTime = Get-Date
    Write-Host ('Starting AXBuild compile. {0} : {1}' -f $ax.AosComputerName, $StartTime) -ForegroundColor Black -BackgroundColor White

    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    } 

    try
    {
        [Boolean]$AOSStopped = $False

        $AXConfig = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AxVersion -IncludeServer

        $AXService = Get-Service -Name $AXConfig.AosServiceName

        if ($StopAOS -and $AXService.Status -eq "Running")
        {
            Write-Host ('Stopping AOS {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
            Stop-AXAOS -ConfigPath $ConfigPath
            $AOSStopped = $True
        }

        $AxBuild = Join-Path $AXConfig.AosBinDir 'AxBuild.exe'
        $Compiler = Join-Path $AXConfig.AosBinDir 'ax32serv.exe'

        if ($LogPath -eq '')
        {
            $LogPath = $AXConfig.AosLogDir
        } 

        $Command = '& "{0}" "xppcompileall" /a="{1}" /c="{2}" /s={3} /l="{4}"' -f $AxBuild, $AXConfig.ClientBinDir, $Compiler, $AXConfig.AosNumber, $LogPath

        if ($NoCleanup)
        {
            $Command = $Command + ' /n'
        }

        if ($PSBoundParameters['Verbose'])
        {
            $Command = $Command + ' /v'
        }

        if ($Workers -gt 0)
        {
            $Command = $Command + ' /w={0}' -f $Workers
        }

        Invoke-Expression $Command

        $AXService = Get-Service -Name $AXConfig.AosServiceName

        if ($AXService.Status -eq "Stopped" -and $AOSStopped)
        {
            Write-Host ('Starting AOS {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
            Start-AXAOS -ConfigPath $ConfigPath
        }

        $LogFile = Join-Path $LogPath 'AxCompileAll.html'
            
        if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
        {
            $MailMsg.Subject = ('AXBuild.exe complete. {0}: {1} - {2}' -f $AXConfig.AosComputerName, $StartTime, (Get-Date))
            $MailMsg.Body = 'See attached.'
            Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority -FileLocation $LogFile
        }
        
       Write-Host ('AXBuild compile complete. {0} : {1} - {2}' -f $AXConfig.AosComputerName, $StartTime, (Get-Date)) -ForegroundColor Black -BackgroundColor White   
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Compile-AXCIL{
###########################################################################################################################################################
#.Synopsis
#  Compiles AX IL for a specific environment.
#.Description
#  Compiles AX IL for a specific environment.
#.Example
#  Compile-AXCIL -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LogFile 'C:\TestLog.log' -Timeout 90
#.Example
#  Compile-AXCIL -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1'
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
# The file location of a script to default parameters used.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline = $True)]
        [String]$LogFile = (Join-Path $env:TEMP 'ILCompile.log'),
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 120,
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

    try
    {   
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $XML = Get-AXAutoRunXML -Command 'CompileIL' -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_CILAutorun'))           
        New-Item $XmlFile -type file -force -value $XML

        Start-AXAutoRun -Ax $ax -XMLFile $XMLFile -LogFile $LogFile -Process 'IL compile' -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
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
    #region Parameters
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
        [String]$VariablePath = ''
    )
    #endregion

    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {   
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $XML = Get-AXAutoRunXML -Command 'Synchronize' -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_DBSync'))           
        New-Item $XmlFile -type file -force -value $XML

        Start-AXAutoRun -Ax $ax -XMLFile $XMLFile -LogFile $LogFile -Process 'Synchronize database' -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Compile-AXAOT{
###########################################################################################################################################################
#.Synopsis
#  Compiles the AOT for a specific environment.
#.Description
#  Compiles the AOT for a specific environment.
#.Example
#  Compile-AXAOT -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -Timeout 300
#.Example
#  Compile-AXAOT -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
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
        [Int]$Timeout = 360,
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

    try
    {   
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $XML = Get-AXAutoRunXML -Command 'CompileApplication' -ExitWhenDone

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_CompileApplication'))           
        New-Item $XmlFile -type file -force -value $XML

        $LogFile = ('C:\Users\{0}\Microsoft\Dynamics Ax\Log\AxCompileAll.html' -f $env:USERNAME)
        
        Start-AXAutoRun -Ax $ax -XMLFile $XMLFile -LogFile $LogFile -Process 'AOT compile' -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Clean-AXArtifacts{
###########################################################################################################################################################
#.Synopsis
#  Deletes all AX client artifact files on local server and can delete server artifact files on the AOS server.
#.Description
#  Deletes all AX client artifact files on local server and can delete server artifact files on the AOS server.
#.Example
#  Clean-AXArtifacts -AllUsers
#.Example
#  Clean-AXArtifacts -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -AllUsers -CleanServer
#.Parameter ConfigPath
#  The path to the AX config files.
#.Parameter CleanServer
#  Used to clean the server artifacts.
#.Parameter AllUsers
#  Used to clean the client files for all users.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline = $True)]
        [Switch]$CleanServer,
        [Parameter(ValueFromPipeline = $True)]
        [Switch]$AllUsers
    )
    #endregion

    [Boolean]$AOSStopped = $False

    if ($CleanServer)
    {
        if ([String]::IsNullOrWhiteSpace($ConfigPath))
        {
            throw 'ConfigPath is required for parameter CleanServer'
        }            
    }

    if ($CleanServer)
    {
        $AXConfig = Get-AXConfig -ConfigPath $ConfigPath -IncludeServer
        $AXService = Get-Service -Name $AXConfig.AosServiceName

        if ($AXService.Status -eq "Running")
        {
            Write-Host ('Stopping AOS {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
            Stop-AXAOS -ConfigPath $ConfigPath
            $AOSStopped = $True
        }
        
        Write-Host ('Cleaning server label artifacts {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
        $CleanPath = Join-Path $AXConfig.AosBinDir 'Application\Appl\Standard'
        Clean-Folder -FolderPath $CleanPath -FilePatterns "ax*.al?"

        Write-Host ('Cleaning server XppIL artifacts {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
        $CleanPath = Join-Path $AXConfig.AosBinDir 'XppIL'
        Clean-Folder -FolderPath $CleanPath -FilePatterns "*"

        Write-Host ('Cleaning server VSAssemblies artifacts {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
        $CleanPath = Join-Path $AXConfig.AosBinDir 'VSAssemblies'
        Clean-Folder -FolderPath $CleanPath -FilePatterns "*"

        $AXService = Get-Service -Name $AXConfig.AosServiceName
        
        if ($AXService.Status -eq "Stopped" -and $AOSStopped)
        {
            Write-Host ('Starting AOS {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
            Start-AXAOS -ConfigPath $ConfigPath
        }
    }

    Write-Host ('Cleaning client cache artifacts : {0}' -f (Get-Date)) -ForegroundColor Red -BackgroundColor White

    if ($AllUsers)
    {
        Clean-Folders -FolderPath 'C:\Users' -FolderPattern '*' -Drilldown -SubFolderPaths 'AppData' -SubFolderPatterns 'Local' -FilePatterns  @('ax_*.auc', 'ax*.kti')
    }
    else
    {
        Clean-Folder -FolderPath $env:LOCALAPPDATA -FilePatterns @('ax_*.auc', 'ax*.kti')
    }
    

    Write-Host ('Cleaning client VSAssemblies artifacts : {0}' -f (Get-Date)) -ForegroundColor Red -BackgroundColor White

    if ($AllUsers)
    {
        Clean-Folders -FolderPaths 'C:\Users' -FolderPattern '*' -Drilldown -SubFolderPaths 'AppData\Local\Microsoft\Dynamics Ax' -SubFolderPatterns 'VSAssemblies*' -FilePatterns '*'
    }
    else
    {
        Clean-Folders -FolderPaths (Join-Path $env:LOCALAPPDATA 'Microsoft\Dynamics AX') -FolderPatterns 'VSAssemblies*' -FilePatterns '*'
    }
}
function Import-AXXPO{
#####################################################################################################################################################################################
#.Synopsis
#  Imports an .xpo file into a specific environment.
#.Description
#  Imports an .xpo file into a specific environment.
#.Example
#  Import-AXXPO -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LogFile 'C:\TestLog.log' -Timeout 10 -ImportFile 'C:\D2DModel_hotfix.xpo'
#.Example
#  Import-AXXPO -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1' -ImportFile 'C:\D2DModel_hotfix.xpo'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter LogFile
#  The path to the log file.
#.Parameter Timeout
#  The amount of time in minutes before the process times out.
#.Parameter ImportFile
#  The path to the .xpo file to import.
#.Parameter Model
#  The Model to work in, in AX.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter AXVersion
#  The AX Version you are running the function against.
#.Parameter VariablePath
# The file location of a script to default parameters used.
######################################################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline = $True)]
        [String]$LogFile = (Join-Path $env:TEMP 'XPOImport.log'),    
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 20,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$ImportFile = '',
        [Parameter(ValueFromPipeline = $True)]
        [String]$Model,
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

    if ($ImportFile -ne '' -and !(Test-Path $ImportFile))
    {
        Throw 'Error: Unable to find import file'
    }

    try
    {   
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $Command = 'XPOImport file="{0}"' -f $ImportFile

        $XML = Get-AXAutoRunXML -Command $Command -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_XPOImport'))           
        New-Item $XmlFile -type file -force -value $XML

        Start-AXAutoRun -Ax $ax -XMLFile $XMLFile -LogFile $LogFile -Process 'XPO import' -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg -Model $Model
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
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
function Sync-AXTFSWorkingFolder{
################################################################################################################################################################################
#.Synopsis
#  Syncs a TFS working folder with a specific label version of code.
#.Description
#  Syncs a TFS working folder with a specific label version of code.
#.Example
#  Sync-AXTFSWorkingFolder
#.Parameter WorkingFolder
#  The TFS working folder to sync.
#.Parameter Label
#  This is used to sync a label version instead of the current version.  Labels should be prefixed with L.
#.Parameter SetLabel
#  This parameter allows you to set a label that doesn't already exist on the current version.
#.Parameter LabelScope
#  This variable allows you to set scope for the label.
#.Parameter Comment
#  This variable allows you to set a label comment.
#.Parameter VariablePath
# The file location of a script to default parameters used.
################################################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [String]$WorkingFolder,
        [String]$Label = '',
        [Switch]$SetLabel,
        [String]$LabelScope = '',
		[String]$Comment = '',
        [String]$VariablePath = ''
    )
    #endregion

    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {
        if ($Label -ne '')
        {
            if ($Label.Substring(0,1) -eq 'L')
            {
                $Version = $Label
                $Label = $Label.Substring(1)
            }
            else
            {
                $Version = 'L' + $Label
            }

            if ($LabelScope -ne '')
            {
                [String]$LabelName = $Label + '@' + $LabelScope  
            }
            else
            {
                [String]$LabelName = $Label
            }

            if (tf.exe labels $LabelName)
            {
                Write-Host ('Getting label version {0} : {1}' -f $Version, (Get-Date)) -ForegroundColor Black -BackgroundColor White
                tf.exe get $WorkingFolder /recursive /force /version:$Version
            }
            else
            {
                Write-Host ('Label {0} not found, getting current version : {1}' -f $Label, (Get-Date)) -ForegroundColor Black -BackgroundColor White
                tf.exe get $WorkingFolder /recursive /force /version:T

                if ($SetLabel -and $LabelName -ne '')
                {
                    Write-Host ('Setting label {0} for working folder {1} : {2}' -f $Label, $WorkingFolder, (Get-Date)) -ForegroundColor Black -BackgroundColor White
                    tf.exe label $LabelName $WorkingFolder /comment:$Comment /recursive
                }
            }
        }
        else
        {
            Write-Host ('Getting current version : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
            tf.exe get $WorkingFolder /recursive /force /version:T
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Restore-AXDatabase{
###########################################################################################################################################################
#.Synopsis
#  Restores a database for a backup file.
#.Description
#  Restores a database for a backup file.
#.Example
#  Restore-AXDatabase -AXDBName 'D2D_AX_BLD' -BackupFilePath 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\D2D_AX_BLD\D2D_AX_BLD_CU7_EmptyBLD.bak'
#.Parameter ServerInstance
#  The name of the server and instance of SQL Server where the database is located.
#.Parameter AXDBName
#  The name of the database to restore.
#.Parameter BackupFilePath
#  The location of the backup file.
#.Parameter AdditionalSQLRestore
#  Additional commands to allow custom restore
#.Parameter Timeout
#  Time in seconds before the restore times out
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter VariablePath
# The file location of a script to default parameters used.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [String]$ServerInstance = 'localhost',
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$AXDBName,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$BackupFilePath,
        [String]$AdditionalSQLRestore = "WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 5",
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 10,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [Net.Mail.MailMessage]$MailMsg,
        [String]$VariablePath = ''
    )
    #endregion

    $StartTime = Get-Date
    Write-Host ('Starting database restore - {0} : {1}' -f $AXDBName, $StartTime) -ForegroundColor Black -BackgroundColor White
    
    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {
        [string] $dbCommand = "USE [master] " +
                              "RESTORE DATABASE [$AXDBName] " +
                              "FROM DISK = N'$BackupFilePath' " + 
                              $AdditionalSQLRestore

        $Timeout = ($Timeout * 60) #minutes to seconds

        Invoke-Sqlcmd -QueryTimeout $Timeout -ServerInstance $ServerInstance -Query $dbCommand -ErrorAction Stop

        if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
        {
            $MailMsg.Subject = ('Database restore complete - {0}: {1} - {2}' -f $AXDBName, $StartTime, (Get-Date))
            $MailMsg.Body = 'See attached.'
            Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
        }

        Write-Host ('Database restore complete - {0} : {1}' -f $AXDBName, (Get-Date)) -ForegroundColor Black -BackgroundColor White
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Combine-AXXPO{
###########################################################################################################################################################
#.Synopsis
#  Creates a combined .xpo file from a directory containing .xpos.
#.Description
#  Creates a combined .xpo file from a directory containing .xpos.
#.Example
#  Combine-AXXPO -XpoDir 'C:\TFS\AX2012\D2D_AX_REL\D2DModel' -CombinedXpoFile 'C:\Builds\1.0.0.1\setup\D2DModelCombined.xpo'
#.Parameter XpoDir
#  The directory holding the .xpo files that need to be combined.
#.Parameter CombinedXpoFile
#  The name and location of the output file.
#.Parameter SpecifiedXpoFile
#  CombineXPOs.exe parameter used to filter the .xpos that are combined.
#.Parameter NoDel
#  CombineXPOs.exe parameter used to allow DEL_ fields to be combined.
#.Parameter utf8
#  CombineXPOs.exe parameter used to set the encoding of the output file.
#.Parameter Threads
#  CombineXPOs.exe parameter used to override the number of threads to use for the process.
#.Parameter ExclusionsFile
#  CombineXPOs.exe parameter used to exclude .xpos from the combining process.
#.Parameter ViewsOnlyOnce
#  CombineXPOs.exe parameter used to enhance performance when combining but can cause reference errors.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter VariablePath
# The file location of a script to default parameters used.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$XpoDir,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$CombinedXpoFile,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SpecifiedXpoFile = '',
        [Parameter(ValueFromPipeline = $True)] 
        [String]$NoDel = '',
        [Parameter(ValueFromPipeline = $True)] 
        [Switch]$utf8,
        [Parameter(ValueFromPipeline = $True)] 
        [Int]$Threads = 0,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$ExclusionsFile = '',
        [Parameter(ValueFromPipeline = $True)] 
        [Switch]$ViewsOnlyOnce,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [Net.Mail.MailMessage]$MailMsg,
        [String]$VariablePath = ''
    )
    #endregion

    $StartTime = Get-Date
    Write-Host ('Generating the XPO file {0} : {1}' -f $CombinedXpoFile, $StartTime) -ForegroundColor Black -BackgroundColor White
    
    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {
        $command = 'CombineXPOs.exe -XpoDir "$XpoDir" -CombinedXpoFile "$CombinedXpoFile"'

        if ($SpecifiedXpoFile -ne '' -and (Test-Path $SpecifiedXpoFile))
        {
            $command = $command + ' -SpecifiedXpoFile "$SpecifiedXpoFile"'
        }

        if ($NoDel -ne '' -and (Test-Path $NoDel))
        {
            $command = $command + ' -NoDel "$NoDel"'
        }

        if ($utf8)
        {
            $command = $command + ' -utf8'
        }

        if ($Threads -gt 0)
        {
            $command = $command + ' -Threads $Threads'
        }

        if ($ExclusionsFile -ne '' -and (Test-Path $ExclusionsFile))
        {
            $command = $command + ' -ExclusionsFile "$ExclusionsFile"'
        }

        if ($ViewsOnlyOnce)
        {
            $command = $command + ' -ViewsOnlyOnce'
        }

        if ($PSBoundParameters['Verbose'])
        {
            $command = $command + ' -Verbose'
        }

        Invoke-Expression $command
        
        if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
        {
            $MailMsg.Subject = ('CombineXPOs complete: {0} - {1}' -f $StartTime, (Get-Date))
            $MailMsg.Body = ('Generated XPO {0}' -f $CombinedXpoFile)
            Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
        }

        Write-Host ('CombineXPOs complete for {0} : {1} - {2}' -f $CombinedXpoFile, $StartTime, (Get-Date)) -ForegroundColor Black -BackgroundColor White
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
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
function Compile-AXXppNode{
###########################################################################################################################################################
#.Synopsis
#  Compiles X++ for a node in the AOT for a specific environment.
#.Description
#  Compiles X++ for a node in the AOT for a specific environment.
#.Example
#  Compile-AXXppNode -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -Node 'Classes'
#.Example
#  Compile-AXXppNode -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -Node 'Visual Studio Projects\Dynamics AX Model Projects'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter Node
#  The AX node to compile.
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
        [String]$Node,
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 90,
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

    try
    {   
        $Ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $Command = 'CompileApplication node="{0}"' -f $Node
        
        $XML = Get-AXAutoRunXML -Command $Command

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($Node + '_CompileNode'))           
        New-Item $XmlFile -type file -force -value $XML

        $LogFile = ('C:\Users\{0}\Microsoft\Dynamics Ax\Log\AxCompileAll.html' -f $env:USERNAME)
        $Process = 'AOT node compile: {0}' -f $Node
        
        Start-AXAutoRun -Ax $Ax -XMLFile $XMLFile -LogFile $LogFile -Process $Process -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Import-AXVSProject{
###########################################################################################################################################################
#.Synopsis
#  Imports a visual studio project into a specific AX environment.
#.Description
#  Imports a visual studio project into a specific AX environment.
#.Example
#  Import-AXVSProject -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -$VSProject 'C:\Test\VSProject.dwproj' -LogFile 'C:\TestLog.log' -Timeout 5
#.Example
#  Import-AXVSProject -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -$VSProject 'C:\Test\VSProject.dwproj' -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter $VSProject
#  The VS project to import.
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
# The file location of a script to default parameters used.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline = $True)]
        [String]$VSProject,
        [Parameter(ValueFromPipeline = $True)]
        [String]$LogFile,
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

    try
    {   
        $Ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $ImportProject = $VSProject.replace('\', '\\');

        $Command = 'Run type="class" name="SysTreeNodeVSProject" method="importProject" parameters="&quot;{0}&quot;"' -f $ImportProject

        $ProjectName = $VSProject.substring($VSProject.lastIndexof('\') + 1)

        if ($LogFile -eq '')
        {
            $LogFile = Join-Path $env:TEMP ('VSProject_{0}.log' -f $ProjectName)
        }

        $XML = Get-AXAutoRunXML -Command $Command -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f $ProjectName)           
        New-Item $XmlFile -type file -force -value $XML

        $Process = 'VS project import: {0}' -f $ProjectName
        Start-AXAutoRun -Ax $Ax -XMLFile $XMLFile -LogFile $LogFile -Process $Process -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Send-EMail{
###########################################################################################################################################################
#.Synopsis
#  Sends an email message.
#.Description
#  Uses parameters to build an smtp call and an email message to send.
#.Example
#  Send-Email -SMTPServer '192.168.0.1' -From 'test@domain.com' -To 'test2@domain.com' -Subject 'Test email' -Body 'Test body' -FileLocation 'C:\Test.txt'
#.Parameter SMTPServer
#  The SMTP server to send the message.
#.Parameter From
#  Who the email is being sent from.
#.Parameter To
#  Who the email is being sent to.
#.Parameter Subject
#  The subject of the email message.
#.Parameter Body
#  The body of the email message.
#.Parameter Priority
#  The priority of the email message.
#.Parameter FileLocation
#  The file location of the file to attach.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [String]$From,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddressCollection]$To,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$Subject,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$Body,
        [Parameter(ValueFromPipeline = $True)]
        [String]$Priority = 'Normal',
        [Parameter(ValueFromPipeline = $True)]
        [String]$FileLocation  = ''
    )
    #endregion

    #Creating a Mail object
    $Msg = new-object Net.Mail.MailMessage

    #Creating SMTP server object
    $SMTP = new-object Net.Mail.SmtpClient($SMTPServer)

    #Email structure 
    $Msg.From = $From

    ForEach ($Email in $To)
    {
        $Msg.To.Add($Email.Address)
    }

    $Msg.subject = $Subject
    $Msg.body = $Body
    $Msg.Priority = $Priority

    try
    {
		#Attach file
		if ($FileLocation -ne '' -and (Test-Path $FileLocation))
		{
			$Attachment = new-object Net.Mail.Attachment($FileLocation)
			$Msg.Attachments.Add($Attachment)
		}

        #Send email
        $SMTP.Send($Msg)
        Write-Host ('Sending Email : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
    }
    catch
    {
        Write-Host ('Error sending email : {0}' -f $Error.ToString()) -ForegroundColor Red -BackgroundColor White
    }
}
function Refresh-AXServices{
###########################################################################################################################################################
#.Synopsis
#  Registers services for a specific environment.
#.Description
#  Registers services for a specific environment.
#.Example
#  Register-AXServices -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LogFile 'C:\TestLog.log' -Timeout 30 -Email 'john.hagler@day2daydynamics.com'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter LogFile
#  The path to the log file.
#.Parameter Timeout
#  The amount of time in minutes before the process times out.
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
    [String]$LogFile = (Join-Path $env:TEMP 'RefreshServices.log'),
    [Parameter(ValueFromPipeline = $True)]
    [Int]$Timeout = 30,
    [Parameter(ValueFromPipeline = $True)] 
    [String]$SMTPServer,
    [Parameter(ValueFromPipeline = $True)]
    [Net.Mail.MailMessage]$MailMsg,
    [Parameter(ValueFromPipeline = $True)]
    [Int]$AXVersion = 6,
    [Parameter(ValueFromPipeline = $True)]
    [String]$VariablePath = ''
    #endregion
)
    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {   
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $Command = 'Run type="class" name="AIFServiceGenerationManager" method="registerServices" parameters=""'
        $XML = Get-AXAutoRunXML -Command $Command -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_RegServicesAutoRun'))           
        New-Item $XmlFile -type file -force -value $XML

        Start-AXAutoRun -Ax $ax -XMLFile $XMLFile -LogFile $LogFile -Process 'AIFServiceGenerationManager::registerServices' -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Refresh-AXAifPort{
########################################################################################################################################################################################################################
#.Synopsis
#  Refreshes an AIF port in a specific AX environment.
#.Description
#  Refreshes an AIF port in a specific AX environment.
#.Example
#  Refresh-AXAifPort -ConfigPath 'C:\Powershell\Compile\D2D_AX_DEV1_VAR.axc' -PortName 'D2DHttpServices' -ServiceClass 'D2DOrderService' -DisabledFields '/D2DOrder/Order/TestField,/D2DOrder/Order/OrderLine/TestField'
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter LogFile
#  The path to the log file.
#.Parameter Timeout
#  The amount of time in minutes before the process times out. Defaults to 10 minutes.
#.Parameter AIFPort
#  The AIF port to refresh.
#.Parameter ServiceClass
#  The AX service class to refresh.
#.Parameter DisabledOperations
#  A comma separated list of service operations that should be disabled.
#.Parameter DisabledFields
#  A comma separated list of fields (xPath) that should be disabled.
#.Parameter RequiredFields
#  A comma separated list of fields (xPath) that should be required.
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter AXVersion
#  The AX Version you are running the function against.
#.Parameter VariablePath
# The file location of a script to default parameters used.
########################################################################################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]$ConfigPath,
        [Parameter(ValueFromPipeline=$True)]
        [String]$LogFile = (Join-Path $env:TEMP 'PortRefresh.log'),
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 10,
        [Parameter(ValueFromPipeline=$True)]
        [String]$AIFPort,
        [Parameter(ValueFromPipeline=$True)]
        [String]$ServiceClass,
        [Parameter(ValueFromPipeline=$True)]
        [String]$DisabledOperations = '',
        [Parameter(ValueFromPipeline=$True)]
        [String]$DisabledFields = '',
        [Parameter(ValueFromPipeline=$True)]
        [String]$RequiredFields = '',
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

    try
    {  
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion 6 -IncludeServer

        $Command = 'Run type="class" name="D2DAutoRunHelper" method="AifPortRefresh" parameters="&quot;{0}&quot;,&quot;{1}&quot;,&quot;{2}&quot;,&quot;{3}&quot;,&quot;{4}&quot;"' -f $AIFPort, $ServiceClass, $DisabledOperations, $DisabledFields, $RequiredFields
        $XML = Get-AXAutoRunXML -Command $Command -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_AifPortAutoRun'))           
        New-Item $XmlFile -type file -force -value $XML

        Start-AXAutoRun -Ax $ax -XMLFile $XMLFile -LogFile $LogFile -Process 'D2DAutoRunHelper::AifPortRefresh' -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Get-AXTFSCombinedXpo{
################################################################################################################################################################################
#.Synopsis
#  Creates an AX .xpo file containing all tfs items for a specific version
#.Description
#  Creates an AX .xpo file containing all tfs items for a specific version
#.Example
#  Get-AXTFSCombinedXpo -Version 'C2500' -OutputFile 'C:\D2DModel_Hotfix.xpo' -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1'
#.Parameter Version
#  The version of the file to grab from TFS. Defaults to T (Current).  L and C are valid prefixes followed by either a label or a changeset'
#.Parameter DateFrom
#  The date to use for finding files.  Combines .xpos that were modified on and after the date supplied. Defaults to 01/01/1900 12:00:00 AM'
#.Parameter DateTo
#  The date to use for finding files.  Combines .xpos that were modified on and before the date supplied. Defaults to 12/31/2154 11:59:59 PM'
#.Parameter OutputFile
#  The name and location of the resulting combined .xpo file.
#.Parameter TFSCollectionUrl
#  The url to connect to TFS.
#.Parameter TFSLocation
#  The server location in TFS to search for files.
#.Parameter VariablePath
# The file location of a script to default parameters used.
################################################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [String]$Version = ('T'),
        [Datetime]$DateFrom = (Get-Date '01/01/1900 12:00:00 AM'),
        [Datetime]$DateTo = (Get-Date '12/31/2154 11:59:59 PM'),
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$OutputFile,
        [String]$TFSCollectionUrl,
        [String]$TFSLocation,
        [String]$VariablePath = ''
    )
    #endregion

    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {
        [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection] $tfs = Get-TfsServer $TFSCollectionUrl
    
        $TempFolder = Join-Path $env:TEMP 'XPOs'
    
        if ((Test-Path -path $TempFolder)) 
        {
            Remove-Item $TempFolder -Recurse
        }

        New-Item $TempFolder -Type Directory

        if ($DateFrom -ne (Get-Date '01/01/1900 12:00:00 AM') -or $DateTo -ne (Get-Date '12/31/2154 11:59:59 PM'))
        {
            $QueryVersion  = 'D{0}~D{1}' -f $DateFrom, $DateTo.AddSeconds(1)
        }
        else
        {
            $QueryVersion = $Version
        }

        switch -Wildcard ($QueryVersion)
        {
            'T' {$FileNames = Get-TfsItemProperty -Server $tfs -Item $TFSLocation -Recurse | 
                                Where-Object {$_.DeletionId -eq '0'} | 
                                Where-Object {$_.ItemType -eq 'File'} | 
                                Where-Object {$_.SourceServerItem -like '*.xpo'} |
                                Select-Object @{Name='Version';Expression={$QueryVersion}}, @{Name='ServerItem';Expression={$_.SourceServerItem}}}

            'C*' {$FileNames = Get-TfsItemHistory $TFSLocation -Server $tfs -Recurse -IncludeItems |  
                                    Select-Object -Expand 'Changes' | 
                                        Where-Object { $_.ChangeType -notlike '*Delete*'} | 
                                    Select-Object -Expand 'Item' | 
                                        Where-Object { $_.ContentLength -gt 0} |  
                                        Where-Object { $_.ServerItem -like '*.xpo'} | 
                                        Where-Object { $_.ChangesetId -eq $QueryVersion.Substring(1)} |
                                    Select-Object -Unique @{Name='Version';Expression={$QueryVersion}}, @{Name='ServerItem';Expression={$_.ServerItem}}}
            'L*' {$FileStr = tf.exe labels /collection:$TFSCollectionUrl $QueryVersion.Substring(1) /format:detailed |
                                    Select-String -pattern '.xpo' |
                                    Select-String -pattern ';X' -NotMatch
                     
                    $FileNames = ForEach ($Str in $FileStr)
                    {
                        $Working = $Str.ToString()
                        $WorkingVersion = 'C' + $Working.Substring(0, $Working.IndexOf(' '))
                        $WorkingFile = $Working.Substring($Working.IndexOf('$'))
                        $Properties = @{Version = $WorkingVersion; ServerItem = $WorkingFile}
                        $WorkingObject = New-Object PSObject -Property $Properties
                        $WorkingObject

                    }} 
            'D*' {$FileNames = Get-TfsItemHistory $TFSLocation -Server $tfs -Version $QueryVersion -Recurse -IncludeItems |  
                                    Select-Object -Expand 'Changes' | 
                                        Where-Object { $_.ChangeType -notlike '*Delete*'} | 
                                    Select-Object -Expand 'Item' | 
                                        Where-Object { $_.ContentLength -gt 0} |  
                                        Where-Object { $_.ServerItem -like '*.xpo'} |
                                    Select-Object -Unique @{Name='Version';Expression={$Version}}, @{Name='ServerItem';Expression={$_.ServerItem}}}
            default {Throw "{0} is not a valid version" -f $Version}
        }

        ForEach ($FileName in $FileNames)
        {
            [String]$File = $FileName.ServerItem
            $Version = $FileName.Version

            #If using Get-TFSItemHistory, it is possible files have been both changed and deleted
            if ($QueryVersion -like 'C*' -or $QueryVersion -like 'D*')
            {
                [String]$FileExists = Get-TfsItemProperty -Server $tfs -Item $TFSLocation -Version $Version -Recurse | 
                                        Where-Object {$_.DeletionId -eq '0'} | 
                                        Where-Object {$_.ItemType -eq 'File'} | 
                                        Where-Object {$_.SourceServerItem -eq $File} |
                                        Select-Object SourceServerItem
            }
            else
            {
                [String]$FileExists = 'true'  
            }

            if ($FileExists -ne '')
            {
                [String]$FileType = $File.Substring(0, $File.LastIndexOf('/'))
                $FileType = $FileType.substring($FileType.lastIndexof('/') + 1)
                $FileType = $FileType.Replace(' ', '')

                $File = $File.substring($File.lastIndexof('/') + 1)
                $File = $FileType + '_' + $File
        
                $File = Join-Path $TempFolder $File
        
                tf.exe view /collection:$TFSCollectionUrl /version:$Version $FileName.ServerItem | Out-File $File -Encoding utf8
            }
        }

        $OutputFolder = $OutputFile.Substring(0, $OutputFile.LastIndexOf('\'))

        if (!(Test-Path -path $OutputFolder)) 
        {
            New-Item $OutputFolder -Type Directory   
        }

        Write-Host ('Generating {0} : {1}' -f $OutputFile, (Get-Date)) -ForegroundColor Black -BackgroundColor White
        CombineXPOs.exe -XpoDir $TempFolder -CombinedXpoFile $OutputFile

        Remove-Item $TempFolder -Recurse
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}
function Clean-AXModel{
###########################################################################################################################################################
#.Synopsis
#  Deletes a model in the local AX environment.
#.Description
#  Deletes a model in the local AX environment.
#.Example
#  Clean-AXModel -ConfigPath 'C:\Powershell\Compile\D2D_AX_DEV1_VAR.axc' -Model 'USR Model' -Layer 'usr' -NoInstallMode
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter Model
#  The AX model to clean.
#.Parameter Model
#  The temp model to move objects into.  Defaults to 'TMP Model'.
#.Parameter Layer
#  The layer to delete from.
#.Parameter AXVersion
#  The AX Version you are running the function against.
#.Parameter NoInstallMode
#  Disables the AX prompt for model changes.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$ConfigPath,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Model,
        [String]$TMPModel = 'TMP Model',
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Layer,
        [Int]$AXVersion = 6,
        [Switch]$NoInstallMode
    )
    #endregion

    try
    {
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $NoData = (Test-AXModelData -Config $ax.AosName -Model $Model -OutVariable $Out | Select-String 'No' -Quiet)

        if ([String]::IsNullOrWhiteSpace($NoData))
        {
            if (Get-AXModel -Config $ax.AosName -Model $TMPModel)
            {
                Uninstall-AXModel -Config $ax.AOSName -Model $TMPModel -NoPrompt
            }
        
            New-AXModel -Config $ax.AosName -Model $TMPModel -Layer $Layer
            Move-AXModel -Config $ax.AosName -Model $Model -TargetModel $TMPModel
            Uninstall-AXModel -Config $ax.AosName -Model $TMPModel -NoPrompt

            Write-Host ('Cleaned {0} in {1} layer : {2}' -f $Model, $Layer, (Get-Date)) -ForegroundColor Black -BackgroundColor White

            if ($NoInstallMode)
            {
                $SQLModelDatabase = $ax.Database + '_model'
                Set-AXModelStore -NoInstallMode -Database $SQLModelDatabase -Server $ax.DatabaseServer -OutVariable out -Verbose
            }
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}


#endregion

#region HiddenFunctions
function Clean-Folder{
###########################################################################################################################################################
#.Synopsis
#  Deletes files in a specific folder based on file patterns.
#.Description
#  Deletes files in a specific folder based on file patterns.
#.Example
#  Clean-Folder -FolderPaths $env:LOCALAPPDATA -FilePatterns 'ax_*.auc'
#.Example
#  Clean-Folder -FolderPaths $env:LOCALAPPDATA -FilePatterns @('ax_*.auc', 'ax*.kti')
#.Parameter FolderPath
#  The path to the files to delete.
#.Parameter FilePatterns
#  The patterns to identify the files to be deleted.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$FolderPath,    
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String[]]$FilePatterns
    )
    #endregion

    if ([System.IO.Directory]::Exists($FolderPath))
    {
        foreach ($FilePattern in $FilePatterns)
        {
            $Files = [System.IO.Directory]::EnumerateFiles($FolderPath, $FilePattern)
    
            foreach ($File in $Files)
            {
                Write-Host ('Deleting {0} : {1}' -f $File, (Get-Date)) -ForegroundColor Black -BackgroundColor White
                Remove-Item $File
            }
        }
    }
}
function Clean-Folders{
###########################################################################################################################################################
#.Synopsis
#  Deletes files in folders based on folder patterns and file patterns.
#.Description
#  Deletes files in folders based on folder patterns and file patterns.
#.Example
#  Clean-Folders -FolderPaths 'C:\Users\dynamics_admin\AppData\Local\Microsoft\Dynamics Ax' -FolderPatterns 'VSAssemblies*' -FilePatterns '*'
#.Example
#  Clean-Folders -FolderPaths 'C:\Users' -FolderPatterns '*' -Drilldown -SubFolderPaths 'AppData' -SubFolderPatterns 'Local' -FilePatterns @('ax_*.auc', 'ax*.kti')
#.Parameter FolderPaths
#  The paths to the folders to loop through.
#.Parameter FolderPatterns
#  The patterns to identify the folders to loop through.
#.Parameter FilePatterns
#  The pattern to identify the files to be deleted.
#.Parameter Drilldown
#  Allows looping through a higher folder than the deleted files by drilling down to the SubFolderPaths. Requires SubFolderPaths and SubFolderPatterns parameter.
#.Parameter SubFolderPaths
#  Uses Join-Path to add the subfolder paths to the current looping path for file deletion.  Required for the Drilldown parameter.
#.Parameter SubFolderPatterns
#  The patterns to identify the folders to delete from. Required for the Drilldown parameter
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
        ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        [String[]]$FolderPaths,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$FolderPatterns,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String[]]$FilePatterns,
        [Parameter(ValueFromPipeline=$True)]
        [Switch]$Drilldown,
        [Parameter(ValueFromPipeline=$True)]
        [String[]]$SubFolderPaths,
        [Parameter(ValueFromPipeline=$True)]
        [String[]]$SubFolderPatterns
    )
    #endregion

    if ($Drilldown)
    {
        if ([String]::IsNullOrWhiteSpace($SubFolderPaths) -or [String]::IsNullOrWhiteSpace($SubFolderPatterns))
        {
            throw 'SubFolderPaths and SubFolderPatterns are required for Drilldown'
        }
    }

    foreach ($FolderPath in $FolderPaths)
    {
        if ([System.IO.Directory]::Exists($FolderPath))
        {
            foreach ($FolderPattern in $FolderPatterns)
            {
                $Folders = [System.IO.Directory]::EnumerateDirectories($FolderPath, $FolderPattern)
    
                foreach ($Folder in $Folders)
                {
                    if ($Drilldown)
                    {
                        foreach ($SubFolderPath in $SubFolderPaths)
                        {
                            $JoinedPath = Join-Path $Folder $SubFolderPath

                            if ([System.IO.Directory]::Exists($JoinedPath))
                            {
                                foreach ($SubFolderPattern in $SubFolderPatterns)
                                {
                                    $SubFolders = [System.IO.Directory]::EnumerateDirectories($JoinedPath, $SubFolderPattern)

                                    foreach ($SubFolder in $SubFolders)
                                    {
                                        Clean-Folder -FolderPath $SubFolder -FilePatterns $FilePatterns
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        Clean-Folder -FolderPath $Folder -FilePatterns $FilePatterns
                    }
                }
            }
        }
    }
}
#endregion