function Clean-AXArtifacts{
###########################################################################################################################################################
#.Synopsis
#  Deletes all AX client artifact files on local server and can delete server artifact files on the AOS server.
#.Description
#  Deletes all AX client artifact files on local server and can delete server artifact files on the AOS server.
#.Example
#  Clean-AXArtifacts -AllUsers
#.Example
#  Clean-AXArtifacts -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -AllUsers -CleanServer
#.Parameter ConfigPath
#  The path to the AX config files.
#.Parameter CleanServer
#  Used to clean the server artifacts.
#.Parameter AllUsers
#  Used to clean the client files for all users.
###########################################################################################################################################################
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $True)]
    [String]$ConfigPath,
    [Parameter(ValueFromPipeline = $True)]
    [Switch]$CleanServer,
    [Parameter(ValueFromPipeline = $True)]
    [Switch]$AllUsers
)

    if (Test-Path $VariablePath)
    {
        ."$VariablePath"
    }

    [Boolean]$AOSStopped = $False

    if ($CleanServer)
    {
        if ([String]::IsNullOrWhiteSpace($ConfigPath))
        {
            throw 'ConfigPath is required for parameter CleanServer'
        }            
    }

    Import-Module DynamicsAXCommunity -DisableNameChecking

    if ($CleanServer)
    {
        $AXConfig = Get-AXConfig -ConfigPath $ConfigPath -IncludeServer
        $AXService = Get-Service -Name $AXConfig.AosServiceName

        if ($AXService.Status -eq "Running")
        {
            Write-Host ('Stopping AOS {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
            Stop-AXAOS -ConfigPath $ConfigPath
            $AOSStopped = $True
        }
        
        Write-Host ('Cleaning server label artifacts {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
        $CleanPath = Join-Path $AXConfig.ServerBinDir 'Application\Appl\Standard'
        Clean-Folder -FolderPath $CleanPath -FilePatterns "ax*.al?"

        Write-Host ('Cleaning server XppIL artifacts {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
        $CleanPath = Join-Path $AXConfig.ServerBinDir 'XppIL'
        Clean-Folder -FolderPath $CleanPath -FilePatterns "*"

        Write-Host ('Cleaning server VSAssemblies artifacts {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
        $CleanPath = Join-Path $AXConfig.ServerBinDir 'VSAssemblies'
        Clean-Folder -FolderPath $CleanPath -FilePatterns "*"

        $AXService = Get-Service -Name $AXConfig.AosServiceName
        
        if ($AXService.Status -eq "Stopped" -and $AOSStopped)
        {
            Write-Host ('Starting AOS {0} - {1}: {2}' -f $AXConfig.AosComputerName, $AXConfig.AosServiceName, (Get-Date)) -ForegroundColor Red -BackgroundColor White
            Start-AXAOS -ConfigPath $ConfigPath
        }
    }

    Write-Host ('Cleaning client cache artifacts : {0}' -f (Get-Date)) -ForegroundColor Red -BackgroundColor White

    if ($AllUsers)
    {
        Clean-Folders -FolderPath 'C:\Users' -FolderPattern '*' -Drilldown -SubFolderPaths 'AppData' -SubFolderPatterns 'Local' -FilePatterns  @('ax_*.auc', 'ax*.kti')
    }
    else
    {
        Clean-Folder -FolderPath $env:LOCALAPPDATA -FilePatterns @('ax_*.auc', 'ax*.kti')
    }
    

    Write-Host ('Cleaning client VSAssemblies artifacts : {0}' -f (Get-Date)) -ForegroundColor Red -BackgroundColor White

    if ($AllUsers)
    {
        Clean-Folders -FolderPaths 'C:\Users' -FolderPattern '*' -Drilldown -SubFolderPaths 'AppData\Local\Microsoft\Dynamics Ax' -SubFolderPatterns 'VSAssemblies*' -FilePatterns '*'
    }
    else
    {
        Clean-Folders -FolderPaths (Join-Path $env:LOCALAPPDATA 'Microsoft\Dynamics AX') -FolderPatterns 'VSAssemblies*' -FilePatterns '*'
    }
}
