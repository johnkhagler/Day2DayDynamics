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
    [String]$VariablePath = ''
)
    Import-Module DynamicsAXCommunity -DisableNameChecking

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