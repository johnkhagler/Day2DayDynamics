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