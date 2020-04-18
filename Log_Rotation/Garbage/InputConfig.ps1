#Если нужно создать конфигурационный файл для сервера удаленно, нужно временно включить авторизацию по CredSSP (нежелательно)
#Указываем сервер на котором нужно включить функционал
#https://www.codeproject.com/Tips/847119/Resolve-Double-Hop-Issue-in-PowerShell-Remoting
#https://blogs.technet.microsoft.com/ashleymcglone/2016/08/30/powershell-remoting-kerberos-double-hop-solved-securely/
$serv = 'vm-co-sccm-01'
#Enable-WSManCredSSP Client –DelegateComputer $serv

$sess = New-PSSession -ComputerName $serv;
Invoke-Command -Session $sess -ScriptBlock {Enable-WSManCredSSP Server -Force}
Remove-PSSession -Session $sess

#Сохранение пароля в файле в зашифрованном виде для дальнейшей автоматизации скриптов
#-------------------------------------------------
#Read-Host -Prompt "Введите пароль" -AsSecureString |ConvertFrom-SecureString | Set-Content C:\windows\temp\p2.txt
$password = Get-Content "C:\windows\temp\p2.txt" | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential("exportcenter\adm_fedorenko",$password)

$sc= {
#Enable-WSManCredSSP Server 
#сетевой ресурс для сбора конфигурационных файлов для задачи ротации логов
$Path = "\\VM-CO-ADM-01\RotationTasks\Config\$env:COMPUTERNAME.ini"
#Создаем хэш таблицу для каждого из серверов и экспортируем ее в конфигурационный файл
$Data = @{
    ServerName = "$env:COMPUTERNAME"
    SourceData = @{
        Source1 = 'C:\InetLogs\Logs\LogFiles'
        Source2 = 'C:\InetLogs\Logs\LogFiles2'
    }
    DestinationData = "C:\InetLogs\Logs\LogFiles\Output_data"
    LogsPath = "\\VM-CO-ADM-01\RotationTasks\Logs\"
    DateTime = @{
        CompressAndMoveDataDays = '3'
        RemoveOldCompressDataDays = '5'
        RemoveOldLoggingDays = '30'
    }
    CompressionLevel = @{
        Default = 'Optimal'
        Low = 'Fastest'
    }
    Services = @{
        Name1 = 'spooler'
        Name2 = 'w3svc'
        Name3 = 'iisadmin'
    }
    processes = @{
        Process1 = "notepad"
        Process2 = "iexplore"
    }
    Commands = @{
        CommandSet1 = @{
        Command = 'iisreset.exe /restart'
        Switch = 'Yes'
        }
        CommandSet2 = @{
        Command = "iisreset.exe /stop"
        Switch = 'No'
        }
        CommandSet3 = @{  
        Command = "iisreset.exe /start"
        Switch = 'No'
        }    
    }
    Recipients = @{
        Recipient1 = 'fedorenko@exportcenter.ru'
        Recipient2 = 'fedorenko@exportcenter.ru'
    }
    


    }|ConvertTo-Json |Set-Content $Path -Force

}#EO $sc


Invoke-Command -ComputerName $serv -ScriptBlock $sc -Authentication CredSSP -Credential $cred



# disable credssp
$sess = New-PSSession -ComputerName $serv;
Invoke-Command -Session $sess -ScriptBlock {disable-WSManCredSSP Server -Verbose}
Remove-PSSession -Session $sess