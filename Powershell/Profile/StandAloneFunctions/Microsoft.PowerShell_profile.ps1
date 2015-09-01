#AX 2012 Management Shell reference
."C:\Program Files\Microsoft Dynamics AX\60\ManagementUtilities\Microsoft.Dynamics.ManagementUtilities.ps1"

#Load Modules
Import-Module DynamicsAXCommunity -DisableNameChecking #DynamicsAXCommunity module

Push-Location
Import-Module SQLPS -DisableNameChecking #SQL Powershell Module
Pop-Location

#D2D Standalone Function reference
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\D2D_PSFunctions.ps1"

#Team Foundation Server References
$env:path += ";C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\" #TF.exe