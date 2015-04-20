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
