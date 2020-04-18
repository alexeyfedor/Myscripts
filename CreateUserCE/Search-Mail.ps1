
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://scedr07cas04.ce.rt.ru/PowerShell
Import-PSSession $ExchangeSession
# блок поиска сообщений
'cekr_main01','cekr_main02' |%{Get-Mailbox -Database $_ |`
Search-Mailbox -SearchQuery "Subject: Крайний день работы*" -TargetFolder delMessages -TargetMailbox 'Sergey_V_Volkov'  -logonly -LogLevel full}


# блок удаления сообщений
'cekr_main01','cekr_main02' |%{Get-Mailbox -Database $_ |`
Search-Mailbox -SearchQuery "Subject: Крайний день работы*" -TargetFolder delMessages -TargetMailbox 'Sergey_V_Volkov'  -DeleteContent -LogLevel full -Confirm:$false}


Remove-PSSession *

