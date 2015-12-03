function Get-AXTFSCombinedXpo{
################################################################################################################################################################################
#.Synopsis
#  Creates an AX .xpo file containing all tfs items for a specific version
#.Description
#  Creates an AX .xpo file containing all tfs items for a specific version
#.Example
#  Get-AXTFSCombinedXpo -Version 'C2500' -OutputFile 'C:\D2DModel_Hotfix.xpo' -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1'
#.Parameter Version
#  The version of the file to grab from TFS. Defaults to T (Current).  L and C are valid prefixes followed by either a label or a changeset'
#.Parameter DateFrom
#  The date to use for finding files.  Combines .xpos that were modified on and after the date supplied. Defaults to 01/01/1900 12:00:00 AM'
#.Parameter DateTo
#  The date to use for finding files.  Combines .xpos that were modified on and before the date supplied. Defaults to 12/31/2154 11:59:59 PM'
#.Parameter OutputFile
#  The name and location of the resulting combined .xpo file.
#.Parameter TFSCollectionUrl
#  The url to connect to TFS.
#.Parameter TFSLocation
#  The server location in TFS to search for files.
#.Parameter VariablePath
# The file location of a script to default parameters used.
################################################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [String]$Version = ('T'),
        [Datetime]$DateFrom = (Get-Date '01/01/1900 12:00:00 AM'),
        [Datetime]$DateTo = (Get-Date '12/31/2154 11:59:59 PM'),
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$OutputFile,
        [String]$TFSCollectionUrl,
        [String]$TFSLocation,
        [String]$VariablePath = ''
    )
    #endregion

    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {
        [Microsoft.TeamFoundation.Client.TfsTeamProjectCollection] $tfs = Get-TfsServer $TFSCollectionUrl
    
        $TempFolder = Join-Path $env:TEMP 'XPOs'
    
        if ((Test-Path -path $TempFolder)) 
        {
            Remove-Item $TempFolder -Recurse
        }

        New-Item $TempFolder -Type Directory

        if ($DateFrom -ne (Get-Date '01/01/1900 12:00:00 AM') -or $DateTo -ne (Get-Date '12/31/2154 11:59:59 PM'))
        {
            $QueryVersion  = 'D{0}~D{1}' -f $DateFrom, $DateTo.AddSeconds(1)
        }
        else
        {
            $QueryVersion = $Version
        }

        switch -Wildcard ($QueryVersion)
        {
            'T' {$FileNames = Get-TfsItemProperty -Server $tfs -Item $TFSLocation -Recurse | 
                                Where-Object {$_.DeletionId -eq '0'} | 
                                Where-Object {$_.ItemType -eq 'File'} | 
                                Where-Object {$_.SourceServerItem -like '*.xpo'} |
                                Select-Object @{Name='Version';Expression={$QueryVersion}}, @{Name='ServerItem';Expression={$_.SourceServerItem}}}

            'C*' {$FileNames = Get-TfsItemHistory $TFSLocation -Server $tfs -Recurse -IncludeItems |  
                                    Select-Object -Expand 'Changes' | 
                                        Where-Object { $_.ChangeType -notlike '*Delete*'} | 
                                    Select-Object -Expand 'Item' | 
                                        Where-Object { $_.ContentLength -gt 0} |  
                                        Where-Object { $_.ServerItem -like '*.xpo'} | 
                                        Where-Object { $_.ChangesetId -eq $QueryVersion.Substring(1)} |
                                    Select-Object -Unique @{Name='Version';Expression={$QueryVersion}}, @{Name='ServerItem';Expression={$_.ServerItem}}}
            'L*' {$FileStr = tf.exe labels /collection:$TFSCollectionUrl $QueryVersion.Substring(1) /format:detailed |
                                    Select-String -pattern '.xpo' |
                                    Select-String -pattern ';X' -NotMatch
                     
                    $FileNames = ForEach ($Str in $FileStr)
                    {
                        $Working = $Str.ToString()
                        $WorkingVersion = 'C' + $Working.Substring(0, $Working.IndexOf(' '))
                        $WorkingFile = $Working.Substring($Working.IndexOf('$'))
                        $Properties = @{Version = $WorkingVersion; ServerItem = $WorkingFile}
                        $WorkingObject = New-Object PSObject -Property $Properties
                        $WorkingObject

                    }} 
            'D*' {$FileNames = Get-TfsItemHistory $TFSLocation -Server $tfs -Version $QueryVersion -Recurse -IncludeItems |  
                                    Select-Object -Expand 'Changes' | 
                                        Where-Object { $_.ChangeType -notlike '*Delete*'} | 
                                    Select-Object -Expand 'Item' | 
                                        Where-Object { $_.ContentLength -gt 0} |  
                                        Where-Object { $_.ServerItem -like '*.xpo'} |
                                    Select-Object -Unique @{Name='Version';Expression={$Version}}, @{Name='ServerItem';Expression={$_.ServerItem}}}
            default {Throw "{0} is not a valid version" -f $Version}
        }

        ForEach ($FileName in $FileNames)
        {
            [String]$File = $FileName.ServerItem
            $Version = $FileName.Version

            #If using Get-TFSItemHistory, it is possible files have been both changed and deleted
            if ($QueryVersion -like 'C*' -or $QueryVersion -like 'D*')
            {
                [String]$FileExists = Get-TfsItemProperty -Server $tfs -Item $TFSLocation -Version $Version -Recurse | 
                                        Where-Object {$_.DeletionId -eq '0'} | 
                                        Where-Object {$_.ItemType -eq 'File'} | 
                                        Where-Object {$_.SourceServerItem -eq $File} |
                                        Select-Object SourceServerItem
            }
            else
            {
                [String]$FileExists = 'true'  
            }

            if ($FileExists -ne '')
            {
                [String]$FileType = $File.Substring(0, $File.LastIndexOf('/'))
                $FileType = $FileType.substring($FileType.lastIndexof('/') + 1)
                $FileType = $FileType.Replace(' ', '')

                $File = $File.substring($File.lastIndexof('/') + 1)
                $File = $FileType + '_' + $File
        
                $File = Join-Path $TempFolder $File
        
                tf.exe view /collection:$TFSCollectionUrl /version:$Version $FileName.ServerItem | Out-File $File -Encoding utf8
            }
        }

        $OutputFolder = $OutputFile.Substring(0, $OutputFile.LastIndexOf('\'))

        if (!(Test-Path -path $OutputFolder)) 
        {
            New-Item $OutputFolder -Type Directory   
        }

        Write-Host ('Generating {0} : {1}' -f $OutputFile, (Get-Date)) -ForegroundColor Black -BackgroundColor White
        CombineXPOs.exe -XpoDir $TempFolder -CombinedXpoFile $OutputFile

        Remove-Item $TempFolder -Recurse
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}

