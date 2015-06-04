function Sync-AXTFSWorkingFolder{
################################################################################################################################################################################
#.Synopsis
#  Creates an AX .xpo file containing all tfs items for a specific version
#.Description
#  Creates an AX .xpo file containing all tfs items for a specific version
#.Example
#  Get-AXTFSCombinedXpo -WorkingFolder 'C:\TFS\AX2012\D2D_AX_REL'
#.Parameter WorkingFolder
#  The TFS working folder to sync.
#.Parameter Label
#  This is used to sync a label version instead of the current version.  Labels should be prefixed with L.
#.Parameter SetLabel
#  This parameter allows you to set a label that doesn't already exist on the current version.
#.Parameter LabelScope
#  This variable allows you to set scope for the label.
#.Parameter VariablePath
# The file location of a script to default parameters used.
################################################################################################################################################################################
[CmdletBinding()]
param(
    [String]$WorkingFolder,
    [String]$Label = '',
    [Switch]$SetLabel,
    [String]$LabelScope = '',
    [String]$VariablePath = '?'
)
    if (Test-Path $VariablePath)
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