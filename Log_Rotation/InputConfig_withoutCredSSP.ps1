#имя сервера, для которого создаем конфигурацию
$serv = 'vm-co-sccm-01'


#-------------------------------------------------
#Read-Host -Prompt "Введите пароль" -AsSecureString |ConvertFrom-SecureString | Set-Content C:\windows\temp\p2.txt
$password = Get-Content "C:\windows\temp\p2.txt" | ConvertTo-SecureString
$cred = New-Object System.Management.Automation.PSCredential("exportcenter\adm_fedorenko",$password)

# для того чтобы избавиться от проблемы двойного хопа при авторизации, создаем  кастомный psdrive. Будем его использовать при выполнении скрипта на удаленной машине (invoke-command). Сам PSDrive подключаем внутри тела скрипта командой New-PSDrive @using:psdrive 
# описание проблематики и решения https://powershellexplained.com/2017-04-22-Powershell-installing-remote-software/?utm_source=blog&utm_medium=blog&utm_content=tags
$psdrive = @{
    Name = "PSDrive"
    PSProvider = "FileSystem"
    Root = "\\VM-CO-ADM-01\RotationTasks\Config"
    Credential = $cred
}


$sc= {

New-PSDrive @using:psdrive 
#сетевой ресурс для сбора конфигурационных файлов для задачи ротации логов
$Path = "\\VM-CO-ADM-01\RotationTasks\Config\$env:COMPUTERNAME.ini"
#Создаем хэш таблицу для каждого из серверов и экспортируем ее в конфигурационный файл
$Data = [ordered]@{
    ServerName = "$env:COMPUTERNAME"
    SourceData = @{
        Source1 = 'C:\inetpub\logs\LogFiles\W3SVC1'
        Source2 = 'C:\inetpub\logs\LogFiles\W3SVC2'
    }
    DestinationData = "E:\Archive_data_test"
    LogsPath = "\\VM-CO-ADM-01\RotationTasks\Logs\"
    DateTime = @{
        CompressAndMoveDataDays = '1'
        RemoveOldCompressDataDays = '3'
        RemoveOldLoggingDays = '35'
    }
    CompressionLevel = @{
        Default = 'Optimal'
        Low = 'Fastest'
    }
    Services = @{
        Name1 = 'spooler'
        #Name2 = 'w3svc'
        #Name3 = 'iisadmin'
    }
    processes = @{
        Process1 = "notepad"
        Process2 = "iexplore"
    }
    Commands = @{
        CommandSet1 = @{
        Command = 'iisreset.exe /restart'
        Switch = 'No'
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


Invoke-Command -ComputerName $serv -ScriptBlock $sc 



