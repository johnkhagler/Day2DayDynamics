#AX Client Configuration File
$ConfigPath = 'C:\Powershell\Compile\D2D_AX2012_DEV1_VAR.axc'

#Email Variables
$SMTPServer = 'smtp.d2ddynamics.com'
$MailMsg = New-Object Net.Mail.MailMessage
$MailMsg.From = 'Functions@D2DDynamics.com'
$MailMsg.To.Add('test@D2DDynamics.com')
$MailMsg.Subject = 'Default subject' #This is generally set in each function but I have a default here to stop email failures
$MailMsg.Body = 'Default body' #This is generally set in each function but I have a default here to stop email failures
#$MailMsg.Priority = 'Normal' #This isn't really necessary as Normal is the default value for Net.Mail.MailMessage.  Should be used if you want to change it.

#System Variables
$AXVersion = 6
#$Workers = 4 --I default to 4 in my environment because it has given me the fastest compile times