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