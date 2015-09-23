#  Send-Email -SMTPServer 'smtp.d2ddynamics.com' -From 'test@domain.com' -To 'test2@domain.com' -Subject 'Test email' -Body 'Test body' -FileLocation 'C:\Test.txt'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Send-Email.ps1"

#  Start-AXBuildCompile -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -SMTPServer 'smtp.d2ddynamics.com' -MailMsg $MailMsg -Workers 4
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Start-AXBuildCompile.ps1"

#  Get-AXAutoRunXML -$Command 'CompileApplication' -LogFile 'C:\TestLog.log' -ExitWhenDone
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Get-AXAutoRunXML.ps1"

#  Start-AXAutoRun -Ax $ax -XMLFile 'C:\AOTCompile.xml' -LogFile 'C:\Test.log' -Process 'AOT compile' -Timeout 480 -SMTPServer 'smtp.d2dynamics.com -MailMsg $MailMsg
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Start-AXAutoRun.ps1"

#  Compile-AXCIL -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LogFile 'C:\TestLog.log' -Timeout 90
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Compile-AXCIL.ps1"

#  Sync-AXDB -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LogFile 'C:\TestLog.log' -Timeout 90
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Sync-AXDB.ps1"

#  Compile-AXAOT -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -Timeout 300
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Compile-AXAOT.ps1"

#  Clean-Folder -FolderPaths $env:LOCALAPPDATA -FilePatterns @('ax_*.auc', 'ax*.kti')
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Clean-Folder.ps1"

#  Clean-Folders -FolderPaths 'C:\Users' -FolderPatterns '*' -Drilldown -SubFolderPaths 'AppData' -SubFolderPatterns 'Local' -FilePatterns @('ax_*.auc', 'ax*.kti')
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Clean-Folders.ps1"

#  Clean-AXArtifacts -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -AllUsers -CleanServer
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Clean-AXArtifacts.ps1"

#  Import-AXXPO -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LogFile 'C:\TestLog.log' -Timeout 10 -ImportFile 'C:\D2DModel_hotfix.xpo'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Import-AXXPO.ps1"

#  Import-AXLabelFile -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -LableFile 'C:\axD2Den-us.ald'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Import-AXLabelFile.ps1"

#  Sync-AXTFSWorkingFolder -WorkingFolder 'C:\TFS\AX2012\D2D_AX_REL'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Sync-AXTFSWorkingFolder.ps1"

#  Restore-AXDatabase -AXDBName 'D2D_AX_BLD' -BackupFilePath 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\D2D_AX_BLD\D2D_AX_BLD_CU7_EmptyBLD.bak'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Restore-AXDatabase.ps1"

#  Combine-AXXPO -XpoDir 'C:\TFS\AX2012\D2D_AX_REL\D2DModel' -CombinedXpoFile 'C:\Builds\1.0.0.1\setup\D2DModelCombined.xpo'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Combine-AXXPO.ps1"

#  Start-AXMSBuildImport -VariablePath 'C:\Powershell\D2D_PSFunctionVariables.ps1' -Layer 'var' -LayerCode 'uerl3958738493' -ModelName 'D2D Model'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Start-AXMSBuildImport.ps1"

#  Compile-AXXppNode -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -Node 'Visual Studio Projects\Dynamics AX Model Projects'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Compile-AXXppNode.ps1"

#  Import-AXVSProject -ConfigPath 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc' -$VSProject 'C:\Test\VSProject.dwproj' -LogFile 'C:\TestLog.log' -Timeout 5
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Import-AXVSProject.ps1"

#  Build-AXModel '1.0.0.1' -VariablePath 'C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Build-AXModel_Variables.ps1'
."C:\VisualStudioOnline\Workspaces\CodePlex\Day2DayDynamics\Powershell\StandAloneFunctions\Function_Build-AXModel.ps1"
