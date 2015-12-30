#Config files
[String]$ConfigPath = 'C:\Powershell\Compile\D2D_AX_TST_VAR.axc'
#Extra layer configs would only be necessary if using an array to loop through multiple model imports in different layers, and only for hotfixes
#[String]$USRConfig = 'C:\Powershell\Compile\D2D_AX_TST_USR.axc'
#[String]$CUSConfig = 'C:\Powershell\Compile\D2D_AX_TST_CUS.axc'
#[String]$VARConfig = 'C:\Powershell\Compile\D2D_AX_TST_VAR.axc'

#AX layer variables
[String]$USRLayerName = "usr"
[String]$CUSLayerName = "cus"
[String]$VARLayerName = "var"

#AX model variables
[String]$USRModelName = "USR Model"
[String]$CUSModelName = "CUS Model"
[String]$VARModelName = "VAR Model"

#Build model arrays for looping
$USRModelToClean = New-Object System.Collections.ArrayList #Array to hold model info for deletion
$USRModelToClean.Add($USRLayerName)
$USRModelToClean.Add($USRModelName)
$CUSModelToClean = New-Object System.Collections.ArrayList #Array to hold model info for deletion
$CUSModelToClean.Add($CUSLayerName)
$CUSModelToClean.Add($CUSModelName)
$VARModelToClean = New-Object System.Collections.ArrayList #Array to hold model info for deletion
$VARModelToClean.Add($VARLayerName)
$VARModelToClean.Add($VARModelName)
$ModelsToClean = New-Object System.Collections.ArrayList #Array to loop through for cleaning
$ModelsToClean.Add($USRModelToClean)
$ModelsToClean.Add($CUSModelToClean)
$ModelsToClean.Add($VARModelToClean)

#Build model arrays for looping (I don't use this as I have a single model and I pass it in when I call the function
#$D2DModel = New-Object System.Collections.ArrayList #Array to hold model info for import
#$D2DModel.Add($VARConfig)
#$D2DModel.Add('C:\Builds\1.0.0.1\D2DModel.axmodel')
#$ModelsToImport = New-Object System.Collections.ArrayList #Array to loop through for importing
#$ModelsToImport.Add($D2DModel)

#Build port arrays for looping
$TestHttpPort = New-Object System.Collections.ArrayList #Array to hold portinfo for refresh
$TestHttpPort.Add('D2DHttpPort') #PortName
$TestHttpPort.Add('D2DTestService') #ServiceClass
$TestHttpPort.Add('') #DisabledOperations
$TestHttpPort.Add('') #DisabledFields
$TestHttpPort.Add('') #RequiredFields
$PortsToRefresh = New-Object System.Collections.ArrayList #Array to loop through for port refresh
$PortsToRefresh.Add($TestHttpPort)

#Build report arrays for looping
$ReportsToDeploy = New-Object System.Collections.ArrayList #Array to loop through reports
$ReportsToDeploy.Add('*')

#Timeout variables in minutes
[Int]$ImportXPOTimeout = 30
[Int]$CompileCILTimeout = 90
[Int]$DBSyncTimeout = 90
[Int]$RefreshServicesTimeout = 30
[Int]$AIFPortRefreshTimeout = 20

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