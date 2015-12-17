function Clean-AXModel{
###########################################################################################################################################################
#.Synopsis
#  Deletes a model in the local AX environment.
#.Description
#  Deletes a model in the local AX environment.
#.Example
#  Clean-AXModel -ConfigPath 'C:\Powershell\Compile\D2D_AX_DEV1_VAR.axc' -Model 'USR Model' -Layer 'usr' -NoInstallMode
#.Parameter ConfigPath
#  The configuration file for the AX instance.
#.Parameter Model
#  The AX model to clean.
#.Parameter Model
#  The temp model to move objects into.  Defaults to 'TMP Model'.
#.Parameter Layer
#  The layer to delete from.
#.Parameter AXVersion
#  The AX Version you are running the function against.
#.Parameter NoInstallMode
#  Disables the AX prompt for model changes.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$ConfigPath,
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Model,
        [String]$TMPModel = 'TMP Model',
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [String]$Layer,
        [Int]$AXVersion = 6,
        [Switch]$NoInstallMode
    )
    #endregion

    try
    {
        $ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AXVersion -IncludeServer

        $NoData = (Test-AXModelData -Config $ax.AosName -Model $Model -OutVariable $Out | Select-String 'No' -Quiet)

        if ([String]::IsNullOrWhiteSpace($NoData))
        {
            if (Get-AXModel -Config $ax.AosName -Model $TMPModel)
            {
                Uninstall-AXModel -Config $ax.AOSName -Model $TMPModel -NoPrompt
            }
        
            New-AXModel -Config $ax.AosName -Model $TMPModel -Layer $Layer
            Move-AXModel -Config $ax.AosName -Model $Model -TargetModel $TMPModel
            Uninstall-AXModel -Config $ax.AosName -Model $TMPModel -NoPrompt

            Write-Host ('Cleaned {0} in {1} layer : {2}' -f $Model, $Layer, (Get-Date)) -ForegroundColor Black -BackgroundColor White

            if ($NoInstallMode)
            {
                $SQLModelDatabase = $ax.Database + '_model'
                Set-AXModelStore -NoInstallMode -Database $SQLModelDatabase -Server $ax.DatabaseServer -OutVariable out -Verbose
            }
        }
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}

