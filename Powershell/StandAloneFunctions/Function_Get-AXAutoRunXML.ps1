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