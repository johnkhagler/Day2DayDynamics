#AX 2012 Management Shell reference
."C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"

#Load Modules
Import-Module DynamicsAXCommunity -DisableNameChecking #DynamicsAXCommunity module
Import-Module D2DDynamics -DisableNameChecking #D2DDynamics module

Push-Location
Import-Module SQLPS -DisableNameChecking #SQL Powershell Module
Pop-Location

#Team Foundation Server References
$env:path += ";C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\" #TF.exe
Add-PSSnapin Microsoft.TeamFoundation.PowerShell #TFS 2012 Power Tools