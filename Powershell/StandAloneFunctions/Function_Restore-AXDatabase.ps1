function Restore-AXDatabase{
###########################################################################################################################################################
#.Synopsis
#  Restores a database for a backup file.
#.Description
#  Restores a database for a backup file.
#.Example
#  Restore-AXDatabase -AXDBName 'D2D_AX_BLD' -BackupFilePath 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\D2D_AX_BLD\D2D_AX_BLD_CU7_EmptyBLD.bak'
#.Parameter ServerInstance
#  The name of the server and instance of SQL Server where the database is located.
#.Parameter AXDBName
#  The name of the database to restore.
#.Parameter BackupFilePath
#  The location of the backup file.
#.Parameter AdditionalSQLRestore
#  Additional commands to allow custom restore
#.Parameter Timeout
#  Time in seconds before the restore times out
#.Parameter SMTPServer
#  The SMTP server used to send the email.
#.Parameter MailMsg
#  A Net.Mail.MailMsg object used for the email information.
#.Parameter VariablePath
# The file location of a script to default parameters used.
###########################################################################################################################################################
    #region Parameters
    [CmdletBinding()]
    param(
        [String]$ServerInstance = 'localhost',
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$AXDBName,
        [Parameter(Mandatory=$True,
        ValueFromPipeline = $True)]
        [ValidateNotNullOrEmpty()]
        [String]$BackupFilePath,
        [String]$AdditionalSQLRestore = "WITH FILE = 1, NOUNLOAD, REPLACE, STATS = 5",
        [Parameter(ValueFromPipeline = $True)]
        [Int]$Timeout = 10,
        [Parameter(ValueFromPipeline = $True)] 
        [String]$SMTPServer,
        [Parameter(ValueFromPipeline = $True)]
        [Net.Mail.MailMessage]$MailMsg,
        [String]$VariablePath = ''
    )
    #endregion

    $StartTime = Get-Date
    Write-Host ('Starting database restore - {0} : {1}' -f $AXDBName, $StartTime) -ForegroundColor Black -BackgroundColor White
    
    if ($VariablePath -ne '' -and (Test-Path $VariablePath))
    {
        ."$VariablePath"
    }

    try
    {
        [string] $dbCommand = "USE [master] " +
                              "RESTORE DATABASE [$AXDBName] " +
                              "FROM DISK = N'$BackupFilePath' " + 
                              $AdditionalSQLRestore

        $Timeout = ($Timeout * 60) #minutes to seconds

        Invoke-Sqlcmd -QueryTimeout $Timeout -ServerInstance $ServerInstance -Query $dbCommand -ErrorAction Stop

        if (($SMTPServer -ne '') -and ($MailMsg.From -ne '') -and ($MailMsg.To -ne '') -and ($MailMsg.Subject -ne '') -and ($MailMsg.Body -ne '') -and ($MailMsg.Priority -ne ''))
        {
            $MailMsg.Subject = ('Database restore complete - {0}: {1} - {2}' -f $AXDBName, $StartTime, (Get-Date))
            $MailMsg.Body = 'See attached.'
            Send-Email -SMTPServer $SMTPServer -From $MailMsg.From -To $MailMsg.To -Subject $MailMsg.Subject -Body $MailMsg.Body -Priority $MailMsg.Priority
        }

        Write-Host ('Database restore complete - {0} : {1}' -f $AXDBName, (Get-Date)) -ForegroundColor Black -BackgroundColor White
    }
    catch 
	{
		Write-Error -ErrorRecord $_
	}
}