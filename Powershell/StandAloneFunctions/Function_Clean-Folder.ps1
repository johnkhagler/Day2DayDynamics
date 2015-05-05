function Clean-Folder{
###########################################################################################################################################################
#.Synopsis
#  Deletes files in a specific folder based on file patterns.
#.Description
#  Deletes files in a specific folder based on file patterns.
#.Example
#  Clean-Folder -FolderPaths $env:LOCALAPPDATA -FilePatterns 'ax_*.auc'
#.Example
#  Clean-Folder -FolderPaths $env:LOCALAPPDATA -FilePatterns @('ax_*.auc', 'ax*.kti')
#.Parameter FolderPath
#  The path to the files to delete.
#.Parameter FilePatterns
#  The patterns to identify the files to be deleted.
###########################################################################################################################################################
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$FolderPath,    
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [String[]]$FilePatterns
)
    if ([System.IO.Directory]::Exists($FolderPath))
    {
        foreach ($FilePattern in $FilePatterns)
        {
            $Files = [System.IO.Directory]::EnumerateFiles($FolderPath, $FilePattern)
    
            foreach ($File in $Files)
            {
                Write-Host ('Deleting {0} : {1}' -f $File, (Get-Date)) -ForegroundColor Black -BackgroundColor White
                Remove-Item $File
            }
        }
    }
}
