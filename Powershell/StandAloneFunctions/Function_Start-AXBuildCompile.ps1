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
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter VariablePath
# The file location of a script to default parameters used.
#.Parameter Workers
#  The number of processes running the build.
#.Parameter AXVersion
#  The AX Version you are running the function against.  The function is only valid for AX 2012 R2 CU7 and above.
######################################################################################################################################################
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $True)]
    [String]$ConfigPath,
    [Parameter(ValueFromPipeline = $True)] 
    [String]$SMTPServer,
    [Parameter(ValueFromPipeline = $True)]
    [Net.Mail.MailMessage]$MailMsg,
    [Parameter(ValueFromPipeline = $True)]
    [String]$VariablePath = '?',
    [Parameter(ValueFromPipeline = $True)]
    [Int]$Workers,
    [Parameter(ValueFromPipeline = $True)]
    [Int]$AXVersion
)
    Import-Module DynamicsAXCommunity -DisableNameChecking

    if (Test-Path $VariablePath)
    {
        ."$VariablePath"
    } 

    $AXConfig = $AXConfig = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AxVersion -IncludeServer

    $LogPath = $AXConfig.ServerLogDir
    $CurrentDir = Get-Location

    if ($Workers -ne 0)
    {
        $WorkersParam = '/workers={0}' -f $Workers
    }
    else
    {
        $WorkersParam = ''
    }

    $BAT =
@'
cd "{0}"
axbuild.exe xppcompileall /s={1} /altbin="{2}" /log="{3}" {4}
cd "{5}"
'@ -f $AXConfig.ServerBinDir, $AXConfig.AosNumber, $AXConfig.ClientBinDir, $LogPath, $WorkersParam, $CurrentDir

    try
    {
        $BATFile = Join-Path $env:TEMP 'AXBuild.bat'           
        New-Item $BATFile -type file -force -value $BAT

        Write-Host ('Starting AXBuild.exe process - {0} : {1}' -f $Process, (Get-Date)) -ForegroundColor Black -BackgroundColor White
        $StartTime = Get-Date

        .$BATFile

        $LogFile = Join-Path $LogPath 'AxCompileAll.html'
            
        if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
        {
            $MailMsg.Subject = ('{0} - AXBuild.exe {1}: {2} - {3}' -f $ax.AosComputerName, $Process, $StartTime, (Get-Date))
            $MailMsg.Body = 'See attached.'
            Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority -FileLocation $LogFile
        }
        else
        {
            Write-Host ('{0} - AXBuild.exe {1}: {2} - {3}.  Missing email parameters.  Email not sent.' -f $ax.AosComputerName, $Process, $StartTime, (Get-Date)) -ForegroundColor Red -BackgroundColor White   
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}