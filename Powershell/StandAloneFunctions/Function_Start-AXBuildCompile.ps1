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