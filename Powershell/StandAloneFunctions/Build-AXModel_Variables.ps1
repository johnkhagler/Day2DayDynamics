#Config files
[String]$VARConfig = 'C:\Powershell\Compile\D2D_AX_BLD_VAR.axc'

#TFS server and working folder locations
[String]$D2DModelServerFolder = "$/AX2012/D2D_AX_REL/D2DModel"
[String]$D2DModelFileFolder = "C:\TFS\AX2012\D2D_AX_REL\D2DModel"

#AX layer variables
[String]$VARLayerName = "var"

#AX model variables
[String]$D2DModelName = "D2D Model"
[String]$D2DModelDescription = "D2D Model for customizations"

#AX layer development license codes
[String]$VARLayerCode = "?????????????????????"

#Build Variables
[String]$BuildFolder = "C:\TFS\builds\{0}\"
[String]$ImportVSProjects = "C:\TFS\AX2012\Automation\D2D\BuildScripts\ImportVSProjects.proj"
[String]$MSBuildPath = 'C:\Windows\Microsoft.NET\Framework\v4.0.30319'

#Model specific build variables
[String]$D2DBuildFile = "D2DModel.xpo" #XPO file for combining 
[String]$D2DModelFile = "D2DModel.axmodel" #Model file for export

#Model arrays for looping
$D2DModelCreate = New-Object System.Collections.ArrayList #Model info
$D2DModelCreate.Add($D2DModelName)
$D2DModelCreate.Add($D2DModelDescription)
$VARModels = New-Object System.Collections.ArrayList #Array to hold VAR models
$VARModels.Add($D2DModelCreate)
$VARModelsCreate = New-Object System.Collections.ArrayList #Array to hold VAR layer import
$VARModelsCreate.Add($VARLayerName)
$VARModelsCreate.Add($VARModels)
$ModelsToCreate = New-Object System.Collections.ArrayList #Array to loop through for import
$ModelsToCreate.Add($VARModelsCreate)

#Label files
[String]$XXXLabelFile = 'C:\TFS\AX2012\D2D_AX_REL\D2DModel\label files\AXXXXen-us.ald'
[String]$D2DLabelFile = 'C:\TFS\AX2012\D2D_AX_REL\D2DModel\label files\AXD2Den-us.ald'

#Label arrays for looping
$VARD2DLabels = New-Object System.Collections.ArrayList #Label files grouped by layer and model
$VARD2DLabels.Add($XXXLabelFile)
$VARD2DLabels.Add($D2DLabelFile)
$VARD2DLabelImport = New-Object System.Collections.ArrayList #Array to hold layer config, model and label arrays
$VARD2DLabelImport.Add($VARConfig)
$VARD2DLabelImport.Add($D2DModelName)
$VARD2DLabelImport.Add($VARD2DLabels)
$LabelImports = New-Object System.Collections.ArrayList #Array to loop through for import
$LabelImports.Add($VARD2DLabelImport)

#Build file arrays for looping
$D2DXPOImport = New-Object System.Collections.ArrayList #Array to loop through build files by model
$D2DXPOImport.Add($VARConfig)
$D2DXPOImport.Add($D2DModelName)
$D2DXPOImport.Add($D2DModelFileFolder)
$D2DXPOImport.Add($D2DBuildFile)
$XPOImports = New-Object System.Collections.ArrayList #Array to loop through for import
$XPOImports.Add($D2DXPOImport)

#VS Project arrays for looping
$D2DVSProjects = New-Object System.Collections.ArrayList #Array to loop through VSProjects by model
$D2DVSProjects.Add($VARConfig)
$D2DVSProjects.Add($VARLayerName)
$D2DVSProjects.Add($VARLayerCode)
$D2DVSProjects.Add($D2DModelName)
$D2DVSProjects.Add($D2DModelFileFolder)
$VSProjectsImports = New-Object System.Collections.ArrayList #Array to loop through for import
$VSProjectsImports.Add($D2DVSProjects)

#Model file arrays for looping
$D2DModelFileExport = New-Object System.Collections.ArrayList #Array to hold D2D model file info
$D2DModelFileExport.Add($D2DModelName)
$D2DModelFileExport.Add($D2DModelFile)
$ModelFileExports = New-Object System.Collections.ArrayList #Array to loop through for export
$ModelFileExports.Add($D2DModelFileExport)

#Timeout variables in minutes
[Int]$ImportLabelFileTimeout = 60
[Int]$ImportXPOTimeout = 120
[Int]$ImportVSBuildTimeout = 60
[Int]$CompileCILTimeout = 90
[Int]$DBSyncTimeout = 90
[Int]$DBRestoreTimeout = 600 #currently in seconds.  Function needs to be changed to make uniform.

#Database restore variables
[String]$DataDatabase = 'D2D_AX_BLD'
[String]$ModelDatabase = 'D2D_AX_BLD_model'
[String]$DataBUFilePath = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\D2D_AX_BLD\D2D_AX_BLD_CU7_EmptyBLD.bak'
[String]$ModelBUFilePath = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\D2D_AX_BLD_model\D2D_AX_BLD_model_CU7_NoVAR.bak'

#Misc variables
[String]$ExchangeRateProviderOanda = 'Classes\ExchangeRateProviderOanda'
[String[]]$NodesToClientCompile = @($ExchangeRateProviderOanda)

#Email variables
$SMTPServer = 'smtp.day2daydynamics.com'
$MailMsg = New-Object Net.Mail.MailMessage
$MailMsg.From = 'Functions@day2daydynamics.com'
$MailMsg.To.Add('john.hagler@day2daydynamics.com')
$MailMsg.Subject = 'Default subject' #This is generally set in each function but I have a default here to stop email failures
$MailMsg.Body = 'Default body' #This is generally set in each function but I have a default here to stop email failures
#$MailMsg.Priority = 'Normal' #This isn't really necessary as Normal is the default value for Net.Mail.MailMessage.  Should be used if you want to change it.

#System Variables
$AXVersion = 6
$Workers = 4 #I default to 4 in my environment because it has given me the fastest compile times