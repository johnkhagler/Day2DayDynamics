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
