#AX 2012 Management Shell reference
."C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1" #(Used for both build and push)

#Load Modules
Import-Module DynamicsAXCommunity -DisableNameChecking #DynamicsAXCommunity module (Used for both build and push)
Import-Module D2DDynamics -DisableNameChecking #D2DDynamics module (Used for both build and push)

Push-Location
Import-Module SQLPS -DisableNameChecking #SQL Powershell Module (Used for build)
Pop-Location

#Team Foundation Server References
$env:path += ";C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\" #TF.exe (Used for build)
Add-PSSnapin Microsoft.TeamFoundation.PowerShell #TFS 2012 Power Tools (Used for build)

#Stand-alone functions
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\D2D_PSFunctions.ps1" #(Used for build and push)