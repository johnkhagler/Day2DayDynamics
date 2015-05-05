function Clean-Folders{
###########################################################################################################################################################
#.Synopsis
#  Deletes files in folders based on folder patterns and file patterns.
#.Description
#  Deletes files in folders based on folder patterns and file patterns.
#.Example
#  Clean-Folders -FolderPaths 'C:\Users\dynamics_admin\AppData\Local\Microsoft\Dynamics Ax' -FolderPatterns 'VSAssemblies*' -FilePatterns '*'
#.Example
#  Clean-Folders -FolderPaths 'C:\Users' -FolderPatterns '*' -Drilldown -SubFolderPaths 'AppData' -SubFolderPatterns 'Local' -FilePatterns @('ax_*.auc', 'ax*.kti')
#.Parameter FolderPaths
#  The paths to the folders to loop through.
#.Parameter FolderPatterns
#  The patterns to identify the folders to loop through.
#.Parameter FilePatterns
#  The pattern to identify the files to be deleted.
#.Parameter Drilldown
#  Allows looping through a higher folder than the deleted files by drilling down to the SubFolderPaths. Requires SubFolderPaths and SubFolderPatterns parameter.
#.Parameter SubFolderPaths
#  Uses Join-Path to add the subfolder paths to the current looping path for file deletion.  Required for the Drilldown parameter.
#.Parameter SubFolderPatterns
#  The patterns to identify the folders to delete from. Required for the Drilldown parameter
###########################################################################################################################################################
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,
    ValueFromPipeline=$True)]
    [ValidateNotNullOrEmpty()]
    [String[]]$FolderPaths,
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$FolderPatterns,
    [Parameter(Mandatory=$True,
    ValueFromPipeline = $True)]
    [ValidateNotNullOrEmpty()]
    [String[]]$FilePatterns,
    [Parameter(ValueFromPipeline=$True)]
    [Switch]$Drilldown,
    [Parameter(ValueFromPipeline=$True)]
    [String[]]$SubFolderPaths,
    [Parameter(ValueFromPipeline=$True)]
    [String[]]$SubFolderPatterns
)
    if ($Drilldown)
    {
        if ([String]::IsNullOrWhiteSpace($SubFolderPaths) -or [String]::IsNullOrWhiteSpace($SubFolderPatterns))
        {
            throw 'SubFolderPaths and SubFolderPatterns are required for Drilldown'
        }
    }

    foreach ($FolderPath in $FolderPaths)
    {
        if ([System.IO.Directory]::Exists($FolderPath))
        {
            foreach ($FolderPattern in $FolderPatterns)
            {
                $Folders = [System.IO.Directory]::EnumerateDirectories($FolderPath, $FolderPattern)
    
                foreach ($Folder in $Folders)
                {
                    if ($Drilldown)
                    {
                        foreach ($SubFolderPath in $SubFolderPaths)
                        {
                            $JoinedPath = Join-Path $Folder $SubFolderPath

                            if ([System.IO.Directory]::Exists($JoinedPath))
                            {
                                foreach ($SubFolderPattern in $SubFolderPatterns)
                                {
                                    $SubFolders = [System.IO.Directory]::EnumerateDirectories($JoinedPath, $SubFolderPattern)

                                    foreach ($SubFolder in $SubFolders)
                                    {
                                        Clean-Folder -FolderPath $SubFolder -FilePatterns $FilePatterns
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        Clean-Folder -FolderPath $Folder -FilePatterns $FilePatterns
                    }
                }
            }
        }
    }
}
