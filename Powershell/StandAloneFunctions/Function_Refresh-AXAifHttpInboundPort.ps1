function Refresh-AXAifHttpInboundPort{
########################################################################################################################################################################################################################
#.Synopsis
#  Refreshes an AIF inbound HTTP port in a specific AX environment.
#.Description
#  Refreshes an AIF inbound HTTP port in a specific AX environment.
#.Example
#  Refresh-AXAifHttpPort -ConfigPath 'C:\Powershell\Compile\D2D_AX_DEV1_VAR.axc' -PortName 'D2DHttpServices' -ServiceClass 'D2DOrderService' -DisabledFields '/D2DOrder/Order/TestField,/D2DOrder/Order/OrderLine/TestField'
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

        $Command = 'Run type="class" name="D2DAutoRunHelper" method="AifHttpInboundPortRefresh" parameters="&quot;{0}&quot;,&quot;{1}&quot;,&quot;{2}&quot;,&quot;{3}&quot;,&quot;{4}&quot;"' -f $AIFPort, $ServiceClass, $DisabledOperations, $DisabledFields, $RequiredFields
        $XML = Get-AXAutoRunXML -Command $Command -ExitWhenDone -LogFile $LogFile

        $XMLFile = Join-Path $env:TEMP ('{0}.xml' -f ($ax.AosComputerName + '_AifHttpPortAutoRun'))           
        New-Item $XmlFile -type file -force -value $XML

        Start-AXAutoRun -Ax $ax -XMLFile $XMLFile -LogFile $LogFile -Process 'D2DAutoRunHelper::AifHttpInboundPortRefresh' -Timeout $Timeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}