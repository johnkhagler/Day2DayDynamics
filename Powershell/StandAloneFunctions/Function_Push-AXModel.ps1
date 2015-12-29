function Push-AXModel{
####################################################################################################################################################################################################
#.Synopsis
#  Pushes an AX model file to a specific environment.
#.Description
#  Pushes an AX model file to a specific environment.
#.Example
#  Push-AXModel -ModelFile 'C:\Builds\1.0.3.0\D2DModel.axmodel' -VariablePath ''C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Push-AXModelVariables.ps1'
#.Parameter ModelFile
#  The AX model file to import.
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter VariablePath
# The file location of a script to default parameters used.
####################################################################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [String]$ModelFile,
        [String]$ConfigPath,
        [String]$VariablePath
    )
    #endregion
    
    try
    {
        if ($VariablePath -ne '' -and (Test-Path $VariablePath))
        {
            ."$VariablePath"
        }
        
        $StartTime = Get-Date        

        if ($ConfigPath -ne '' -and (Test-Path $ConfigPath))
        {
            $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer
        }
        else
        {
            throw "The ConfigPath parameter was not found."
        }

        Write-Host ('Starting AX push on {0} : {1}' -f $ax.AosComputerName, $StartTime) -ForegroundColor Black -BackgroundColor White

        if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Priority -ne ''))
        {
            $MailMsg.Subject = ('Starting AX push on {0} : {1}' -f $ax.AosComputerName, $StartTime)
            $MailMsg.Body = $MailMsg.Subject
            Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
        }

        #Stop the AOS
        Stop-AXAOS -ConfigPath $ConfigPath

        #Clean up existing models
        foreach ($ModelToClean in $ModelsToClean)
        {
            [String]$LayerName = $ModelToClean[0]
            [String]$ModelName = $ModelToClean[1]

            Clean-AXModel -ConfigPath $ConfigPath -Layer $LayerName -Model $ModelName
        }
        
        #Install the model files
        if ($ModelFile -ne '' -and (Test-Path $ModelFile))
        {
            $ParameterModel = New-Object System.Collections.ArrayList #Array to hold the model
            $ParameterModel.Add($ConfigPath)
            $ParameterModel.Add($ModelFile)
            $ModelsToImport = New-Object System.Collections.ArrayList #Array to loop through for importing
            $ModelsToImport.Add($ParameterModel)
        }

        $SQLModelDatabase = $ax.Database + '_model'

        foreach ($ModelToImport in $ModelsToImport)
        {
            $LayerConfig = $ModelToImport[0]
            $ModelFile = $ModelToImport[1]

            Write-Host ('Installing model file {0} : {1}' -f $ModelFile, (Get-Date)) -ForegroundColor Black -BackgroundColor White
            Install-AXModel -Config $ax.AosName -File $ModelFile -Details -Conflict Overwrite -NoPrompt
            
            if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Priority -ne ''))
            {
                $MailMsg.Subject = ('Installed model file {0} on {1} : {2}' -f $ModelFile, $ax.AOSComputerName, (Get-Date))
                $MailMsg.Body = $MailMsg.Subject
                Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
            }

            Write-Host ('Installed model file {0} on {1} : {2}' -f $ModelFile, $ax.AOSComputerName, (Get-Date)) -ForegroundColor Black -BackgroundColor White
         
            #Set the install mode
            Set-AXModelStore -NoInstallMode -Database $SQLModelDatabase -Server $ax.DatabaseServer -OutVariable out -Verbose

            #Install hotfixes
            Start-AXAOS -ConfigPath $ConfigPath

            $HotfixFolder = Join-Path $ModelFile.Substring(0, $ModelFile.LastIndexOf('\')) 'hotfixes'

            if (Test-Path $HotfixFolder)
            {
                $HotfixFiles = Get-ChildItem $HotfixFolder | Sort LastWriteTime

                ForEach ($HotfixFile in $HotfixFiles)
                {
                    $Hotfix = Join-Path $HotfixFolder $HotfixFile.Name
                    $LogFile = Join-Path $env:TEMP ('{0}.log' -f $HotfixFile.Name)
                    Import-AXXPO -ConfigPath $LayerConfig -LogFile $LogFile -ImportFile $Hotfix -Timeout $ImportXPOTimeout -SMTPServer $SMTPServer -MailMsg $MailMsg

                    #Import again to clear up any order issues
                    $LogFile = Join-Path $env:TEMP ('{0}_2.log' -f $HotfixFile.Name)
                    Import-AXXPO -ConfigPath $LayerConfig -LogFile $LogFile -ImportFile $Hotfix -Timeout $ImportXPOTimeout -SMTPServer $SMTPServer -MailMsg $MailMsg
                }
            }

            Stop-AXAOS -ConfigPath $ConfigPath
        }

        #Compile the AOT
        Start-AXBuildCompile -ConfigPath $ConfigPath -Workers $Workers -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg

        #Start the AOS
        Start-AXAOS -ConfigPath $ConfigPath

        #Compile any nodes that may have issues in server compile
        foreach ($Node in $NodesToClientCompile)
        {
            Compile-AXXppNode -ConfigPath $ConfigPath -Node $Node -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg
        }

        #Compile IL
        $LogFile = Join-Path $env:TEMP 'ILCompile.log'
        Compile-AXCIL -ConfigPath $ConfigPath -LogFile $LogFile -Timeout $CompileCILTimeout -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg

        #Cleanup artifacts
        Clean-AXArtifacts -ConfigPath $ConfigPath -AllUsers -CleanServer

        #Synchronize database
        $LogFile = Join-Path $env:TEMP 'DBSync.log'
        Sync-AXDB -ConfigPath $ConfigPath -LogFile $LogFile -Timeout $DBSyncTimeout -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg

        #Refresh the services
        $LogFile = Join-Path $env:TEMP 'ServiceRefresh.log'
        Refresh-AXServices -ConfigPath $ConfigPath -LogFile $LogFile -Timeout $RefreshServicesTimeout -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg

        foreach ($PortToRefresh in $PortsToRefresh)
        {
            [String]$PortName = $PortToRefresh[0]
            [String]$ServiceClass = $PortToRefresh[1]
            [String]$DisabledOperations = $PortToRefresh[2]
            [String]$DisabledFields = $PortToRefresh[3]
            [String]$RequiredFields = $PortToRefresh[4]

            $LogFile = Join-Path $env:TEMP ('{0}_Refresh.log' -f $PortName)
            Refresh-AXAifHttpInboundPort -ConfigPath $ConfigPath -LogFile $LogFile -Timeout $AIFPortRefreshTimeout -AIFPort $PortName -ServiceClass $ServiceClass -DisabledOperations $DisabledOperations -DisabledFields $DisabledFields -RequiredFields $RequiredFields -AXVersion $AXVersion -SMTPServer $SMTPServer -MailMsg $MailMsg
        }

        #Bounce the AOS
        Restart-AXAOS -ConfigPath $ConfigPath
        
        if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Priority -ne ''))
        {
            $MailMsg.Subject = ('Model push on {0} complete : {1} - {2}' -f $ax.AosComputerName, $StartTime, (Get-Date))
            $MailMsg.Body = $MailMsg.Subject
            Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
        }

        Write-Host ('Model push on {0} complete : {1} - {2}' -f $ax.AosComputerName, $StartTime, (Get-Date)) -ForegroundColor Black -BackgroundColor White
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}