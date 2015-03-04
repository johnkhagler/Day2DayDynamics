# This PowerShell module was released under the Ms-PL license
# http://www.opensource.org/licenses/ms-pl.html
# This script was originally intended for use with Microsoft Dynamics AX 2012
# and maintained and distributed as a project on CodePlex
# http://dynamicsaxbuild.codeplex.com

[int]$global:AxVersionPreference = 6
[int]$LastAxWithAppl = 5

#region Cmdlets
Function Compile-AXIL
{
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[string]$LogPath,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=-1)
	#endregion
	
	try
	{
		RunAxStartupCmd -Command CompileIL @PSBoundParameters
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}	
}
Function Compile-AXXpp
{
	<#
		.SYNOPSIS
		Compiles Dynamics AX application.
	#>
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[string]$LogPath,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=-1)
	#endregion
	
	try
	{
		RunAxStartupCmd -Command CompileAll @PSBoundParameters
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Get-AXConfig
{
	<#
		.SYNOPSIS
		Gets Dynamics AX client configuration details.
		
		.DESCRIPTION
		Gets details about a particular Dynamics AX client configuration.
		To retrieve information about server components (AOS, database) too, use the IncludeServer parameter.
		
		Use the List parameter to get all configuration names from Windows registry.
		
		.PARAMETER ConfigName
		Specifies Dynamics AX client configuration name saved in Windows registry. If not specified, the active configuration
		is used.
		
		.PARAMETER ConfigPath
		Specifies Dynamics AX client configuration file (.axc).	
		
		.PARAMETER List
		Gets configuration names and statuses from Windows registry.
		
		.PARAMETER IncludeServer
		Returns also server-side properties, e.g. database name. If AOS is on a remote machine, you may be asked for 
		user credentials.
		
		.PARAMETER Credential
		Specifies user credentials for connection to a remote AOS, if the IncludeServer parameter is used.
		
		.PARAMETER AxVersion
		Specifies major Dynamics AX version number (e.g. 5).
		
		.LINK
		Set-AXConfig
	#>
	
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="Name",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="Name")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="Path")]
		[Alias("Path")]
		[string]$ConfigPath,
		
		[Parameter(ParameterSetName="List")]
		[switch]$List,
		
		[Parameter(ParameterSetName="Name")]
		[Parameter(ParameterSetName="Path")]
		[Alias("Server")]
		[switch]$IncludeServer,
		
		[Parameter(ParameterSetName="Name")]
		[Parameter(ParameterSetName="Path")]
		[System.Management.Automation.PSCredential]$Credential=$global:Credential,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference)
	#endregion
	
	try
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			"List" #List configurations
			{
				$regPath = "HKCU:\SOFTWARE\Microsoft\Dynamics\$AxVersion.0\Configuration"
				if (!(Test-Path $regPath))
				{
					throw New-Object System.Management.Automation.ItemNotFoundException "Configuration for Dynamics AX $AxVersion.0 was not found in Windows registry."
				}
				$activeConfig = Get-ItemProperty $regPath | Select -Expand Current

				return ls $regPath | select `
					@{Name="Name"; Expression={$_.PSChildName}}, `
					@{Name="Active"; Expression={$_.PSChildName -eq $activeConfig}}
			}
			"Name" #Load configuration from Windows registry
			{
				if (!$ConfigName)
				{
					$ConfigName = Get-AXConfig -List -AxVersion $AxVersion | ? {$_.Active} | select -Expand Name
				}
				$registryPath = "HKCU:\SOFTWARE\Microsoft\Dynamics\$AxVersion.0\Configuration\$ConfigName"
				if (!(Test-Path $registryPath))
				{
					throw "Configuration '$ConfigName' does not exist in Windows registry."
				}
				
				$aosDefinitionString = Get-ItemProperty $registryPath | Select -ExpandProperty aos2
				$clientBinDir = Get-ItemProperty $registryPath | Select -ExpandProperty binDir
				$clientLogDir = Get-ItemProperty $registryPath | Select -ExpandProperty logDir
				
				$properties = @{
					ConfigName = $ConfigName
					ClientBinDir = $clientBinDir
					ClientLogDir = $clientLogDir
				}	
			}
			"Path" 	#Load configuration from file
			{
				$ConfigPath = [Management.Automation.WildcardPattern]::Escape($ConfigPath)
				if (!(Test-Path $ConfigPath))
				{
					throw New-Object System.Management.Automation.ItemNotFoundException "Configuration '$ConfigPath' does not exist."
				}
				
				$aosDefinitionString = ExtractConfigTextProperty $ConfigPath 'aos2'
				$clientBinDir = (ExtractConfigTextProperty $ConfigPath 'bindir')
				$clientLogDir = (ExtractConfigTextProperty $ConfigPath 'logdir')
				
				$properties = @{
					ClientBinDir = $clientBinDir
					ClientLogDir = $clientLogDir
					FilePath = $ConfigPath
				}
			}
		}
		
		if ($IncludeServer)
		{
			$properties += (GetAosDetails $AosDefinitionString -Credential $Credential -Version $AxVersion)
		}
		return New-Object PSObject -Property $Properties
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Restart-AXAOS
{
	<#
		.SYNOPSIS
		Restart Dynamics AX AOS service.	
		
		.DESCRIPTION
		Restarts the  Windows services of Microsoft Dynamics AX Application Object Server (AOS)
		on a local or remote computer. The command waits until restarting is finished.
		
		.PARAMETER ConfigName
		Specifies Dynamics AX client configuration name pointing to AOS to restart.	
		
		.PARAMETER ConfigPath
		Specifies Dynamics AX client configuration file (.axc) pointing to AOS to restart.		
		
		.PARAMETER AxVersion
		Specifies major Dynamics AX version number (e.g. 5).
	#>
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
	
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
		
		[System.Management.Automation.PSCredential]$Credential=$global:Credential,
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference)
	#endregion
	try
	{
		RunAosCommand -Action "Restart" @PSBoundParameters
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Set-AXConfig
{
	<#
		.SYNOPSIS
		Sets active client configuration.
		
		.DESCRIPTION
		Sets active configuration used by Dynamics AX client in Windows registry.
		
		.PARAMETER ConfigName
		Specifies AX configuration name. It must already exist in Window registry.
		
		.PARAMETER AxVersion
		Specifies major Dynamics AX version number (e.g. 5).
		
		.LINK
		Get-AXConfig
	#>
	[CmdletBinding(SupportsShouldProcess=$true)]
	Param(
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[Parameter(Mandatory=$true)]
		[string]$ConfigName,
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference
	)
	try
	{
		$ConfigName = [Management.Automation.WildcardPattern]::Escape($ConfigName)
		$configs = Get-AXConfig -List -AxVersion $AxVersion -ErrorAction Stop
		$config = $configs | ?{$_.Name -eq $ConfigName}
		if (!$config)
		{
			throw New-Object System.Management.Automation.ItemNotFoundException "Configuration '$ConfigName' does not exist."
		}
		if ($config.Active -eq $true)
		{
			Write-Verbose "Configuration '$ConfigName' is already active."	
		}
		else
		{
			$configPath = "HKCU:\SOFTWARE\Microsoft\Dynamics\$AxVersion.0\Configuration"
			Set-ItemProperty -Path $configPath -Name Current -Value $ConfigName
			Write-Verbose "Active configuration changed to '$ConfigName'."			
		}
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Start-AXAOS
{
	<#
		.SYNOPSIS
		Start Dynamics AX AOS service.	
		
		.DESCRIPTION
		Starts the  Windows service of Microsoft Dynamics AX Application Object Server (AOS)
		on a local or remote computer. The command waits until restarting is finished.
		
		.PARAMETER ConfigName
		Specifies Dynamics AX client configuration name pointing to AOS to start.	
		
		.PARAMETER ConfigPath
		Specifies Dynamics AX client configuration file (.axc) pointing to AOS to start.		
		
		.PARAMETER AxVersion
		Specifies major Dynamics AX version number (e.g. 5).
	#>
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
	
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
		
		[System.Management.Automation.PSCredential]$Credential=$global:Credential,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference)
	#endregion
	try
	{
		RunAosCommand -Action "Start" @PSBoundParameters
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Start-AXClient
{
	<#
		.SYNOPSIS
		Starts Dynamics AX client.
		
		.DESCRIPTION
		Starts Dynamics AX client. You can specify configuration to be used
		and parameters for AX client process.
	#>
		
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="Name",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="Name")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Position=0,
			Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="Path")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[Parameter(Position=1)]
		[string[]]$ArgumentList,
		
		[string]$LogPath,
		[switch]$PassThru,
		[switch]$LazyLoading,
		[switch]$NoModalBoxes,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference)
	#endregion

	try
	{
		if ($ConfigPath)
		{
			$ax = Get-AXConfig -ConfigPath $ConfigPath -AxVersion $AxVersion
		}
		else
		{
			$ax = Get-AXConfig -ConfigName $ConfigName -AxVersion $AxVersion
		}		
		
		if ($ax -eq $null){ return }
	
		if ($ax.FilePath)
		{
			$ArgumentList += "`"$($ax.FilePath)`""
		}
		else
		{
			$ArgumentList += "`"-regconfig=$($ax.ConfigName)`""
		}
		
		if ($PsCmdlet.ShouldProcess("$ArgumentList", "Start Dynamics AX client"))
		{
			if ($LazyLoading)
			{
				$ArgumentList += "-lazyclassloading"
				$ArgumentList += "-lazytableloading"
			}
			if ($LogPath)
			{
				$ArgumentList += "`"-logdir=$LogPath`""
			}	
			if ($NoModalBoxes)
			{
				$ArgumentList += "-internal=noModalBoxes"				
			}
			Start-Process (Join-Path $ax.ClientBinDir "ax32.exe") -ArgumentList $ArgumentList -PassThru:$PassThru -Verbose:$VerbosePreference
		}
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
	
}
Function Stop-AXAOS
{
	<#
		.SYNOPSIS
		Stop Dynamics AX AOS service.	
		
		.DESCRIPTION
		Stops the  Windows services of Microsoft Dynamics AX Application Object Server (AOS)
		on a local or remote computer. The command waits until restarting is finished.
		
		.PARAMETER ConfigName
		Specifies Dynamics AX client configuration name pointing to AOS to stop.	
		
		.PARAMETER ConfigPath
		Specifies Dynamics AX client configuration file (.axc) pointing to AOS to stop.		
		
		.PARAMETER AxVersion
		Specifies major Dynamics AX version number (e.g. 5).
	#>
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
	
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
		
		[System.Management.Automation.PSCredential]$Credential=$global:Credential,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference)
	#endregion
	try
	{
		RunAosCommand -Action "Stop" @PSBoundParameters
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Synchronize-AXDatabase
{
	<#
		.SYNOPSIS
		Synchronizes Dynamics AX database.
		
		.DESCRIPTION
		Synchronizes Dynamics AX database with tables and other objects defined
		by application layer.
	#>
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[string]$LogPath,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=-1)
	#endregion
	
	try
	{
		RunAxStartupCmd -Command Synchronize @PSBoundParameters
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Synchronize-AXVCS
{
	<#
		.SYNOPSIS
		Synchronizes Dynamics AX with a model.
		
		.DESCRIPTION
		Synchronizes Dynamics AX application objects with a model in
		Version Control System.
	#>
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[Parameter(Mandatory=$true)]
		[string[]]$Model,
		
		[string]$LogPath,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=-1)
	#endregion
	
	foreach ($m in $Model)
	{
		if ($AxVersion -le $LastAxWithAppl)
		{
			Write-Error "Synchronize-AXVCS is not supported in Dynamics AX $AxVersion."
			Exit
		}
		
		try
		{
			$PSBoundParameters.Remove("Model") | Out-Null
			RunAxStartupCmd -Command "SyncVCS_$m" @PSBoundParameters
		}
		catch
		{
			Write-Error -ErrorRecord $_
		}
	}
}
Function Update-AXXRef
{
	<#
		.SYNOPSIS
		Updates cross-references.
		
		.DESCRIPTION
		Updates cross-references between objects in Dynamics AX application.
	#>
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[string]$LogPath,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=-1)
	#endregion

	try
	{
		RunAxStartupCmd -Command xRefAll @PSBoundParameters
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
}
Function Update-AXXRefIndex
{
	<#
		.SYNOPSIS
		Rebuilds database indexes for Dynamics AX tables related to cross-references.
		
		.DESCRIPTION
		Rebuilds indexes in SQL Server database for Dynamics AX tables. Only tables related
		to cross-reference functionality are affected.
		
		Index rebuild may improve performance of cross-reference functionality.
	#>
	
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[ValidatePattern('^[^\\]*$')]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=[UInt16]::MaxValue)
	#endregion
	
	try
	{
		if (!(CheckAndAddSqlSnapin))
		{
			throw "SQL Server snappin could not be loaded."
		}

		if ($Timeout -le 0)
		{
			$Timeout = [UInt16]::MaxValue
		}

		$PSBoundParameters.Remove("Timeout") | Out-Null
		$ax = Get-AXConfig -IncludeServer @PSBoundParameters
		
		if ($PsCmdlet.ShouldProcess("Server $($ax.DatabaseServer), DB $($ax.Database)", "Update statistics for xRef tables"))
		{
			Invoke-Sqlcmd -ServerInstance $ax.DatabaseServer -Database $ax.Database -QueryTimeout $Timeout `
						-Query "EXEC sp_Msforeachtable @command1 ='ALTER INDEX ALL ON ? REBUILD', @whereand = 'and o.name like `"xRef%`"'" 
		}
	}
	catch
	{
		Write-Error -ErrorRecord $_
	}
	
}
#endregion

#region Helper methods
Function CheckAndAddSqlSnapin
{
	#Returns true if SQL Snapin is ready, false otherwise.
	#Adds the snapin if needed.
	
	$sqlSnapinName = 'SqlServerCmdletSnapin*'
	#If SQL Server snap-in is not loaded	
	if (!(Get-PSSnapin | ?{$_.Name -like $sqlSnapinName}))
	{
		#If snappin found
		if (Get-PSSnapin -Registered | ?{$_.Name -like $sqlSnapinName})
		{
			Add-PSSnapin $sqlSnapinName
		}
		else
		{
			return $false
		}
	}
	return $true;
}
Function ExtractConfigTextProperty
{
	Param(
		[Parameter(Mandatory=$true)]
		[Alias("Path")]
		[string]$ConfigPath,
		[Parameter(Mandatory=$true)]
		[string]$Property
	)
	
	$line = (Select-String $ConfigPath -Pattern $Property -SimpleMatch).Line
	if (!$line)
	{
		throw "Property $property was not found in the configuration file"
	}
	$line = $line.Trim()
	$line.Substring($Property.Length + ",Text,".Length)
}
Function GetAosCommandProvider
{
	Param([string]$Action)
	
	switch ($Action)
	{
		"Start"
		{
			@{
				Description = "Start AOS"
				Command = {param($ServiceName) Start-Service -Name $ServiceName}
			}	
		}
		"Stop"
		{
			@{
				Description = "Stop AOS"
				Command = {param($ServiceName) Stop-Service -Name $ServiceName}				
			}
		}
		"Restart"
		{
			@{
				Description = "Restart AOS"
				Command = {param($ServiceName) Restart-Service -Name $ServiceName}			
			}
		}
	}
}
Function GetAosDetails
{
	#If multiple AOSes are defined in AX configuration, just the first one is used
	Param(
		[Parameter(Mandatory=$true)]
		[string]$AosDefinitionString,
		[System.Management.Automation.PSCredential]$Credential=$global:Credential,
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference
	)	
	
	
	#Take first AOS only
	[string]$aosFullName = $AosDefinitionString.Split(";") | select -First 1
	$aosName, $aosComputerName, $aosPort = SplitAXAosName $aosFullName
	$isRemote = $aosComputerName -ne $Env:COMPUTERNAME
	
	#region ScriptBlock
	$scriptBlock = {
		Param($AosNumber,
			$AosPort,
			$AxVersion,
			[bool]$IsRemote,
			$aosName)
		
		#region ConvertAosPortToAosNumber
		$origLocation = Get-Location
		cd "HKLM:\SYSTEM\CurrentControlSet\services\Dynamics Server\$AxVersion.0"
		$aosNumber = ls | ? -FilterScript {(Get-ItemProperty (Join-Path $_.PSChildName (Get-ItemProperty -Path $_.PSChildName |
			Select -ExpandProperty Current))).Port -eq $AosPort} | select -ExpandProperty PSChildName
		cd $origLocation
		#endregion
		
		$pathToAosKey = "HKLM:\SYSTEM\CurrentControlSet\services\Dynamics Server\$AxVersion.0\$aosNumber"
		$aosActiveConfig = Get-ItemProperty $pathToAosKey | Select -ExpandProperty Current
		$currentProperties = Get-ItemProperty (Join-Path $pathToAosKey $aosActiveConfig)
		$serverbindir = $currentProperties | Select -ExpandProperty bindir
		$serverlogdir = $currentProperties | Select -ExpandProperty logdir
		$dbserver = $currentProperties | Select -ExpandProperty dbserver
		$dbname = $currentProperties | Select -ExpandProperty database
		
		$data = @{
			AosComputerName = $Env:COMPUTERNAME
			AosNumber = $aosNumber
			AosName = $aosName
			AosPort = $aosPort
			AosServiceName = ("AOS$($AxVersion)0`${0:D2}" -f $aosNumber)
			DatabaseServer = $dbserver
			Database = $dbname
			IsAosRemote = $isRemote
			ServerBinDir = $serverbindir
			ServerLogDir = $serverlogdir
		}
		
		if ($AxVersion -le $LastAxWithAppl)
		{
			$applRootDir = ($currentProperties | Select -ExpandProperty directory)
			$data.ApplName = ($currentProperties | Select -ExpandProperty application)
			$data.ApplDir = "$applRootDir\Appl\$($data.ApplName)"
		}
		$data
	}
	#endregion
	
	if ($isRemote)
	{
		if ($Credential -eq $null)
		{
			$Credential = $global:Credential = Get-Credential	
		}
		Invoke-Command -ComputerName $aosComputerName -Credential $Credential -ScriptBlock $scriptBlock -ArgumentList $aosNumber,$aosPort,$axVersion,$isRemote,$aosName
	}
	else
	{
		& $scriptBlock -AosNumber $AosNumber -AosPort $AosPort -AxVersion $AxVersion -IsRemote $isRemote
	}
}
Function RunAosCommand
{
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[Alias("Name")]
		[string]$ConfigName,
	
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
		
		[ValidateSet("Start", "Stop", "Restart")]
		[string]$Action="Restart",

		[System.Management.Automation.PSCredential]$Credential=$global:Credential,
		
		[int]$AxVersion=$AxVersionPreference)
	#endregion

	$commandData = GetAosCommandProvider $Action #TODO delete
	
	$PSBoundParameters.Remove("Action") | Out-Null
	$axData = Get-AXConfig -IncludeServer @PSBoundParameters
	$serviceName = $axData.AosServiceName
	
	if ($axData.IsAosRemote)
	{
		if ($global:Credential -eq $null)
		{
			$Credential = $global:Credential = Get-Credential	
		}
		else
		{
			$Credential = $global:Credential
		}
		
		if ($PsCmdlet.ShouldProcess("$serviceName ($($axData.AosComputerName))", $commandData.Description))
		{
			Invoke-Command -ScriptBlock $commandData.Command -ArgumentList $serviceName `
				-ComputerName $axData.AosComputerName -Credential $Credential 
		}
	}
	else
	{
		switch ($Action)
		{
			"Start" {Start-Service -Name $ServiceName}
			"Stop" {Stop-Service -Name $ServiceName}
			"Restart" {Restart-Service -Name $ServiceName}
		}
	}
}
Function RunAxClientAndWait
{
	#region Parameters
	[CmdletBinding(
		DefaultParameterSetName="Name",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="Name")]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,ParameterSetName="Path")]
		[Alias("Path")]
		[string]$ConfigPath,
	
		[Alias("Arguments")]
		[string[]]$ArgumentList,
		
		[string]$LogPath,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=-1,
		
		[Alias("tm")]
		[string]$TimeoutMessage = "Timeout expired. Operation was unable to complete in $Timeout seconds.")
	#endregion
	if ($Timeout -ge 0)
	{
		$timeoutMiliseconds = $Timeout * 1000;
	}
	else #Accept all negative numbers, change them to -1 expected by WaitForExit()
	{
		$timeoutMiliseconds = -1
	}
	
	$PSBoundParameters.Remove("Timeout") | Out-Null
	$PSBoundParameters.Remove("TimeoutMessage") | Out-Null
	
	$startTime = Get-Date 
	$process = Start-AxClient -PassThru -LazyLoading -NoModalBoxes @PSBoundParameters -ErrorAction "Stop"

	if ($process -and !$WhatIfPreference)
	{
		if ($Timeout -ge 0)
		{
			Write-Verbose "Waiting for process to finish (timeout $Timeout seconds)."
		}
		else
		{
			Write-Verbose "Waiting for process to finish (no timeout)."
		}
		if (!$process.WaitForExit($timeoutMiliseconds))
		{
			$process.Kill()
			throw New-Object System.TimeoutException $TimeoutMessage
		}
		Write-Verbose "Process finished."

		#Look whether any connection error occured (AX seems not to return ExitCode)
		$eventsAfter = $startTime.Subtract((New-TimeSpan -Seconds 1)) #Remove one second to see events occured in the same second when process started
		$lastErrorMsg = Get-EventLog -LogName "Application" -Source "Microsoft Dynamics AX" -EntryType "Error" -InstanceId 110 `
			-After ($eventsAfter) | select -expand ReplacementStrings -First 1 | where {$_}
		
		if ($lastErrorMsg)
		{
			throw $lastErrorMsg
		}
	}
}
Function RunAxStartupCmd
{
	#region Parameters
	[CmdletBinding(DefaultParameterSetName="ConfigName",
		SupportsShouldProcess=$true)]
	Param(
		[Parameter(Position=0,
			ParameterSetName="ConfigName")]
		[Alias("Name")]
		[string]$ConfigName,
		
		[Parameter(Mandatory=$true,
			ValueFromPipeline=$true,
			ValueFromPipelineByPropertyName=$true,
			ParameterSetName="ConfigPath")]
		[Alias("Path")]
		[string]$ConfigPath,
		
		[Parameter(Mandatory=$true)]
		[string]$Command,
	
		[string]$LogPath,
		
		[Alias("Version")]
		[int]$AxVersion=$AxVersionPreference,
	
		[int]$Timeout=-1)
	#endregion
	Process
	{
		$PSBoundParameters.Remove("Command") | Out-Null
		RunAxClientAndWait -ArgumentList "-startupCmd=$Command" @PSBoundParameters
	}
}
Function SplitAXAosName
{
	Param(
		[Parameter(Mandatory=$true)]
		[string]$AosFullName
	)
	$aosName, $computerNameAndPort = $AosFullName.Split("@")
    $computerName, $port = $computerNameAndPort.Split(":")
    return $aosName, $computerName, $port
}
#endregion