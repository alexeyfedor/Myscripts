
<#тех. задание
Глубина хранения архивов в днях
Комфортная глубина - 30 дней. Минимально допустимая глубина - 15 дней.

Список служб, которые необходимо останавливать в период ротации логов
Останавливать нужно службу AdService. Также лучше делать рестарт IIS, чтобы возможные логи web-service тоже освободились. При этом за последние пару дней лучше логи оставлять на сервере. 
То есть в итого, если например сегодня (14.11) запускаем процедуру переноса логов, то за 13/11 и за 12/11 остаются на сервере, предыдущие переносятся в архив, а в архиве удяляются все, что ранее 14/10.

Время, когда можно запустить процедуру ротации. Службы будут остановлены на период ротации логов и после выполнения процедуры будут запущены, т.е. сервис в момент выполнения задачи не будет доступен.
Предлагается использовать окно с 00:00 до 02:00. Если 2-х часов для выполнения ротации будет недостаточно, просьба проинформировать для выполнения оптимизации расписания регулярных обработок.
#>

#имя сервера, для которого создаем конфигурацию
$serv = 'vm-co-ins-02'

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
        Source1 = 'D:\AdInsure-PROD'
        Source2 = 'D:\AdInsure-RC'
        Source3 = 'D:\IIS\LogFiles'
    }
    DestinationData = @{
        Destination1 = 'D:\Archive\AdInsure-PROD'
        Destination2 = 'D:\Archive\AdInsure-RC'
        Destination3 = 'D:\Archive\IIS'
    }
    LogsPath = "\\VM-CO-ADM-01\RotationTasks\Logs\"
    DateTime = @{
        CompressAndMoveDataDays = '3'
        RemoveOldCompressDataDays = '30'
        RemoveOldLoggingDays = '30'
    }
    CompressionLevel = @{
        Default = 'Optimal'
        Low = 'Fastest'
    }
    Services = @{
        Name1 = 'AdServiceAdInsureExiar-RC'
        Name2 = 'AdServiceAdInsureExiar-PROD'
        Name3 = 'iisadmin'
    }
    processes = @{
        Process1 = "Adacta.Service.JobRunner"
        Process2 = "iexplore"
    }
    Commands = @{
        CommandSet1 = @{
        Command = "iisreset.exe /restart"
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
    
  

    }|ConvertTo-Json -Compress|Set-Content $Path -Force   #для  posh v4 нужно использовать ключ -compress. Иначе при конвертации появляется ошибка. Но в этом случае ini файл становится трудно читаеммым. Альренативный вариант - ставить posh 5.1, или делать конфигрурационный файл на хосте сposh 5.1

}#EO $sc


Invoke-Command -ComputerName $serv -ScriptBlock $sc



