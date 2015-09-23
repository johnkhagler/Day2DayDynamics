Function Build-AXModel {
################################################################################################################
#.Synopsis
#  Creates an AXModel build.
#.Description
#  Uses a build number parameter to create an AX model build.
#.Example
#  Build-AXModel -BuildNumber '1.0.0.1'
#.Example
#  Build-AXModel '1.0.0.1' -VariablePath 'C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Build-AXModel_Variables.ps1'
#.Parameter BuildNumber
#  The build number for the model.
#.Parameter ConfigPath
#  The configuration file that points to the build environment.
#.Parameter VariablePath
#  The path to the file that holds the build parameters.
################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True, 
        HelpMessage='What is the build number?')]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({$_ -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'})] 
        [String]$BuildNumber,
        [String]$ConfigPath,
        [String]$VariablePath
    )
    #endregion 
    
    [String]$BuildStart = ('{0}' -f (Get-Date))
    Write-Host ('AX build started : {0}' -f $BuildStart) -ForegroundColor Black -BackgroundColor White

    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Priority -ne ''))
    {
        $MailMsg.Subject = ('AX Build started : {0}' -f $BuildStart)
        $MailMsg.Body = $MailMsg.Subject
        Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
    }
       
    #region Setup build variables
    #Variables
    [String]$BuildFolder = $BuildFolder -f $BuildNumber
    [String]$BuildLogFolder = Join-Path $BuildFolder ('logs\')    
    [String]$BuildSetupFolder = Join-Path $BuildFolder ('setup\')
    [IO.Directory]::CreateDirectory($BuildLogFolder)
    [IO.Directory]::CreateDirectory($BuildSetupFolder) 

    $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion 6 -IncludeServer 
    #endregion    
    #region Prep build environment
    #Step 1: Sync the working folder with the desired version and set the TFS label if necessary
    [String]$Comment = 'Build {0}: Scope = {1}' -f $BuildNumber, $DDCModelServerFolder
    Sync-AXTFSWorkingFolder -WorkingFolder $DDCModelFileFolder -Label $BuildNumber -SetLabel -LabelScope $DDCModelServerFolder -Comment $Comment

    #Step 2: Stop the AOS
    Write-Host ('Stopping the AOS : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
    Stop-AXAOS -ConfigPath $ConfigPath

    #Step 3: Restore vanilla environment
    Restore-AXDatabase -AXDBName $DataDatabase -BackupFilePath $DataBUFilePath -Timeout $DBRestoreTimeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    Restore-AXDatabase -AXDBName $ModelDatabase -BackupFilePath $ModelBUFilePath -Timeout $DBRestoreTimeout -SMTPServer $SMTPServer -MailMsg $MailMsg

    #Step 4: Create new blank models
    foreach ($LayerModels in $ModelsToCreate)
    {
        [String]$Layer = $LayerModels[0]
        [Array[]]$Models = $LayerModels[1]

        foreach ($Model in $Models)
        {
            [String]$ModelName = $Model[0]
            [String]$ModelDescription = $Model[1]

            New-AXModel -Config $ax.AosName -Model $ModelName -Layer $Layer
            $ManifestProperty = 'Description={0}' -f $ModelDescription
            Edit-AXModelManifest -Model $ModelName -ManifestProperty $ManifestProperty
            $ManifestProperty = 'Version={0}' -f $BuildNumber
            Edit-AXModelManifest -Model $ModelName -ManifestProperty $ManifestProperty
        }
    }

    #Step 5: Delete artifact files
    Clean-AXArtifacts -ConfigPath $ConfigPath -AllUsers -CleanServer

    #Step 6: Start the AOS
    Write-Host ('Starting the AOS : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
    Start-AXAOS -ConfigPath $ConfigPath

    #Step 7: Generate the combined xpo files
    $BuildFiles = New-Object System.Collections.ArrayList
    $ImportFile = New-Object System.Collections.ArrayList

    foreach($XPOImport in $XPOImports)
    {
        
        [String]$Config = $XPOImport[0]
        [String]$ModelName = $XPOImport[1]
        [String]$ModelFileFolder = $XPOImport[2]
        [String]$ModelBuildFile = $XPOImport[3]
        
        
        $BuildFile = Join-Path $BuildSetupFolder ($ModelBuildFile)
        Combine-AXXPO -XpoDir $ModelFileFolder -CombinedXpoFile $BuildFile -SMTPServer $SMTPServer -MailMsg $MailMsg

        $ImportFile.Clear()
        $ImportFile.Add($Config)
        $ImportFile.Add($ModelName)
        $ImportFile.Add($BuildFile)
        $BuildFiles.Add($ImportFile)
    }
    #endregion
    #region Import/Compile AX
    #Step 8: Load label files
    foreach ($LabelImport in $LabelImports)
    {
        [String]$LabelConfig = $LabelImport[0]
        [String]$LabelModel = $LabelImport[1]
        [String[]]$Labels = $LabelImport[2]

        foreach ($Label in $Labels)
        {
            Import-AXLabelFile -ConfigPath $LabelConfig -Model $LabelModel -LabelFile $Label -Timeout $ImportLabelFileTimeout -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg
        }
    }
    
    #Step 9: Load combined XPOs
    foreach($BuildFile in $BuildFiles)
    {
        [String]$Config = $BuildFile[0]
        [String]$ModelName = $BuildFile[1]
        [String]$XPOFile = $BuildFile[2]

        #Load combined XPOs
        $LogFile = Join-Path $BuildLogFolder ('XPOImport_{0}.log' -f $ModelName.Substring(0,3))
        Import-AXXPO -ConfigPath $Config -LogFile $LogFile -Timeout $ImportXPOTimeout -ImportFile $XPOFile -Model $ModelName -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg
    
        #Reload combined XPOs to ensure no dependency errors
        $LogFile = Join-Path $BuildLogFolder ('XPOImport_{0}_2.log' -f  $ModelName.Substring(0,3))
        Import-AXXPO -ConfigPath $Config -LogFile $LogFile -Timeout $ImportXPOTimeout -ImportFile $XPOFile -Model $ModelName -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg
    }

    #Step 10: Compile and load Visual Studio projects
    foreach ($VSProjectsImport in $VSProjectsImports)
    {
        [String]$Config = $VSProjectsImport[0]
        [String]$LayerName = $VSProjectsImport[1]
        [String]$LayerCode = $VSProjectsImport[2]
        [String]$ModelName = $VSProjectsImport[3]
        [String]$ModelFileFolder = $VSProjectsImport[4]

        Start-AXMSBuildImport -ConfigPath $Config -MSBuildPath $MSBuildPath -ImportVSProjectsFile $ImportVSProjects -ModelFileFolder $ModelFileFolder -Layer $LayerName -LayerCode $LayerCode -ModelName $ModelName -BuildLogFolder $BuildLogFolder -Timeout $ImportVSBuildTimeout -SMTPServer $SMTPServer -MailMsg $MailMsg
    }
    
    #Step 11: Compile the AOT
    Start-AXBuildCompile -ConfigPath $ConfigPath -Workers $Workers -StopAOS -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg
    #Compile any nodes that may have issues in server compile
    foreach ($Node in $NodesToClientCompile)
    {
        Compile-AXXppNode -ConfigPath $ConfigPath -Node $Node -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg
    }

    #Step 12: Compile CIL
    $LogFile = Join-Path $BuildLogFolder 'GenerateIL.log'
    Compile-AXCIL -ConfigPath $ConfigPath -LogFile $LogFile -Timeout $CompileCILTimeout -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg

    #Step 13: Synchronize the AX Database
    $LogFile = Join-Path $BuildLogFolder 'DBSyncBuild.log'
    Sync-AXDB -ConfigPath $ConfigPath -LogFile $LogFile -Timeout $DBSyncTimeout -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg

    #Step 14: Delete artifact files
    Clean-AXArtifacts -ConfigPath $ConfigPath -AllUsers -CleanServer
    #endregion
    #region Export model
    #Step 15: Export model file
    #Stop the AOS.  This step is necessary to fix an issue with label files not being exported correctly.
    Write-Host ('Stopping the AOS : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
    Stop-AXAOS -ConfigPath $ConfigPath

    foreach($ModelFileExport in $ModelFileExports)
    {
        $ModelName = $ModelFileExport[0]
        $ModelFile = $ModelFileExport[1]

        Write-Host ('Exporting model file for {0}: {1}' -f $ModelName, (Get-Date)) -ForegroundColor Black -BackgroundColor White
        if (Test-Path (Join-Path $BuildFolder $ModelFile))
        {
            Remove-Item (Join-Path $BuildFolder $ModelFile)
        }
        Export-AXModel -Model $ModelName -File (Join-Path $BuildFolder $ModelFile)
    }

    #Start the AOS
    Write-Host ('Starting the AOS : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
    Start-AXAOS -ConfigPath $ConfigPath
    #endregion  
    
    if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Priority -ne ''))
    {
        $MailMsg.Subject = ('AX Build complete : {0} - {1}' -f $BuildStart, (Get-Date))
        $MailMsg.Body = $MailMsg.Subject
        Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
    }
    
    Write-Host ('AX Build complete : {0} - {1}' -f $BuildStart, (Get-Date)) -ForegroundColor Black -BackgroundColor White 
}