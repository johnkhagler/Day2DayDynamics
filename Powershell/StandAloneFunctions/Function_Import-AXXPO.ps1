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
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $True)]
    [String]$ConfigPath,
    [Parameter(ValueFromPipeline = $True)]
    [String]$LogFile = (Join-Path $env:TEMP 'XPOImport.log'),    
    [Parameter(ValueFromPipeline = $True)]
    [Int]$Timeout = 20,
    [Parameter(ValueFromPipeline = $True)]
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
    Import-Module DynamicsAXCommunity -DisableNameChecking
        
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