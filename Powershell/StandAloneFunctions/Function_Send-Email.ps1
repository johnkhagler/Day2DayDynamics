function Send-EMail{
###########################################################################################################################################################
#.Synopsis
#  Sends an email message.
#.Description
#  Uses parameters to build an smtp call and an email message to send.
#.Example
#  Send-Email -SMTPServer '192.168.0.1' -From 'test@domain.com' -To 'test2@domain.com' -Subject 'Test email' -Body 'Test body' -FileLocation 'C:\Test.txt'
#.Parameter SMTPServer
#  The SMTP server to send the message.
#.Parameter From
#  Who the email is being sent from.
#.Parameter To
#  Who the email is being sent to.
#.Parameter Subject
#  The subject of the email message.
#.Parameter Body
#  The body of the email message.
#.Parameter Priority
#  The priority of the email message.
#.Parameter FileLocation
#  The file location of the file to attach.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [String]$From,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddressCollection]$To,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$Subject,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$Body,
        [Parameter(ValueFromPipeline = $True)]
        [String]$Priority = 'Normal',
        [Parameter(ValueFromPipeline = $True)]
        [String]$FileLocation  = ''
    )
    #endregion

    #Creating a Mail object
    $Msg = new-object Net.Mail.MailMessage

    #Creating SMTP server object
    $SMTP = new-object Net.Mail.SmtpClient($SMTPServer)

    #Email structure 
    $Msg.From = $From

    ForEach ($Email in $To)
    {
        $Msg.To.Add($Email.Address)
    }

    $Msg.subject = $Subject
    $Msg.body = $Body
    $Msg.Priority = $Priority

    try
    {
		#Attach file
		if ($FileLocation -ne '' -and (Test-Path $FileLocation))
		{
			$Attachment = new-object Net.Mail.Attachment($FileLocation)
			$Msg.Attachments.Add($Attachment)
		}

        #Send email
        $SMTP.Send($Msg)
        Write-Host ('Sending Email : {0}' -f (Get-Date)) -ForegroundColor Black -BackgroundColor White
    }
    catch
    {
        Write-Host ('Error sending email : {0}' -f $Error.ToString()) -ForegroundColor Red -BackgroundColor White
    }
}