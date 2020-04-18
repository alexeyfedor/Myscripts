<#
Техническое задание
Функционал:

1.	Настройка параметров через ini файл
a.	Каталоги с ротируемыми/архивируемыми логами
b.	Каталоги с архивами логов (куда помещаются архивы логов)
c.	Перечень останавливаемых/запускаемых служб
d.	Ключ включающий/отключающий архивацию логов
e.	Параметр определяющий глубину хранения архивов логов
f.	Параметр определяющий формат именования архивов логов
g.	Параметр определяющий путь к папке с логами работы данного скрипта
2.	Выполняемые задачи
a.	Архивация логов согласно пункту 1a и 1 f с проверкой корректности остановки служб, если заданы останавливаемые службы
b.	Помещение архивов логов согласно пункту 1b
c.	Остановка служб, в случае необходимости до начала архивации логов и запуск после окончания архивации логов. Учет зависимостей запуска служб. Пункт 1с
d.	Возможность отключения/включения архивации согласно пункту 1d
e.	Очистка архивов логов согласно пункту 1e
f.	Очистка логов в исходных каталогов после успешной архивации
g.	Логирование проводимых скриптом действий, пункт 1g

Возможно пригодится оповещение по электронной почте

#>

#-----------------------------------------------------------------------------
#для Adinsure
<#
Есть 2 варианта, как хранятся логи в root-папке
1)	лежит дерево подпапок по типам логов, которое заканчивается папкой с датой сбора логов, например:
- D:\AdInsure-PROD\AdService\20190318
- D:\AdInsure-PROD\AdService\20190319

- D:\AdInsure-PROD\NPoco\Adacta.IIS.WebService-Exiar-PROD\002.085.3001.000\20190320
- D:\AdInsure-PROD\NPoco\Adacta.IIS.WebService-Exiar-PROD\002.085.3001.000\20190321

- D:\AdInsure-PROD\WebService\20190320
- D:\AdInsure-PROD\WebService\20190321
2)	лежит дерево подпапок по типам логов, которое заканчивается файлом текущих логов и файлами с указанием даты логов в названии/расширении, например:
- D:\AdInsure-PROD\API\AdInsure-APIFacade.txt (логи текущего дня)
- D:\AdInsure-PROD\API\AdInsure-APIFacade.log20190312
- D:\AdInsure-PROD\API\AdInsure-APIFacade.log20190320

- D:\AdInsure-PROD\IdentityServer\identity_server-debug-2019-03-20.txt
- D:\AdInsure-PROD\IdentityServer\identity_server-debug-2019-03-20.txt
- D:\AdInsure-PROD\IdentityServer\identity_server-debug-2019-03-21.txt (логи текущего дня)

#>
#-----------------------------------------------------------------------------
$ErrorActionPreference = Stop

$new_date = (Get-Date -Format 'MM-dd-yyyy_hh:mm:ss')
#сетевой ресурс для сбора конфигурационных файлов для задачи ротации логов
$Path = "\\VM-CO-ADM-01\RotationTasks\Config\$env:COMPUTERNAME.ini"
#Создаем хэш таблицу для каждого из серверов и экспортируем ее в конфигурационный файл. Реализовано в скрипте InputConfig.ps1. Здесь для информации
<#$Data = @{
    ServerName = "$env:COMPUTERNAME"
    SourceData = @{
        Source1 = 'C:\InetLogs\Logs\LogFiles'
        Source2 = 'C:\InetLogs\Logs\LogFiles2'
    }
    DestinationData = "C:\InetLogs\Logs\LogFiles\Output_data"
    LogsPath = "\\VM-CO-ADM-01\RotationTasks\Logs\"
    DateTime = @{
        CompressAndMoveDataDays = '10'
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
        Process1 = "notepad.exe"
    }
    Commands = @{
        RestartIIS = 'iisreset.exe /restart'
        StopIIS = "iisreset.exe /stop"
        StartIIS = "iisreset.exe /start"      
    }
    Recipients = @{
        Recipient1 = 'fedorenko@exportcenter.ru'
        Recipient2 = 'fedorenko@exportcenter.ru'
    } 


    }|ConvertTo-Json |Set-Content $Path -Force

}
#>
#---------------------------------------------------------------------------
#функция записи операций
Function Write-Log
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path='C:\Logs\PowerShellLog.log',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Error","Warn","Info")]
        [string]$Level="Info",
        
        [Parameter(Mandatory=$false)]
        [switch]$NoClobber
    )

    Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
        # If the file already exists and NoClobber was specified, do not write to the log.
        if ((Test-Path $Path) -AND $NoClobber) {
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name."
            Return
            }

        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
        elseif (!(Test-Path $Path)) {
            Write-Verbose "Creating $Path."
            $NewLogFile = New-Item $Path -Force -ItemType File
            }

        else {
            # Nothing to see here yet.
            }

        # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Write message to error, warning, or verbose pipeline and specify $LevelText
        switch ($Level) {
            'Error' {
                Write-Error $Message
                $LevelText = 'ERROR:'
                }
            'Warn' {
                Write-Warning $Message
                $LevelText = 'WARNING:'
                }
            'Info' {
                Write-Verbose $Message
                $LevelText = 'INFO:'
                }
            }
        
        # Write log entry to $Path
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    }
}

#---------------------------------------------------------------------------
Function Set-AlternatingRows {
	<#
	.SYNOPSIS
		Simple function to alternate the row colors in an HTML table
	.DESCRIPTION
		This function accepts pipeline input from ConvertTo-HTML or any
		string with HTML in it.  It will then search for <tr> and replace 
		it with <tr class=(something)>.  With the combination of CSS it
		can set alternating colors on table rows.
		
		CSS requirements:
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		
		Classnames can be anything and are configurable when executing the
		function.  Colors can, of course, be set to your preference.
		
		This function does not add CSS to your report, so you must provide
		the style sheet, typically part of the ConvertTo-HTML cmdlet using
		the -Head parameter.
	.PARAMETER Line
		String containing the HTML line, typically piped in through the
		pipeline.
	.PARAMETER CSSEvenClass
		Define which CSS class is your "even" row and color.
	.PARAMETER CSSOddClass
		Define which CSS class is your "odd" row and color.
	.EXAMPLE $Report | ConvertTo-HTML -Head $Header | Set-AlternateRows -CSSEvenClass even -CSSOddClass odd | Out-File HTMLReport.html
	
		$Header can be defined with a here-string as:
		$Header = @"
		<style>
		TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
		TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
		TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
		.odd  { background-color:#ffffff; }
		.even { background-color:#dddddd; }
		</style>
		"@
		
		This will produce a table with alternating white and grey rows.  Custom CSS
		is defined in the $Header string and included with the table thanks to the -Head
		parameter in ConvertTo-HTML.
	.NOTES
		Author:         Martin Pugh
		Twitter:        @thesurlyadm1n
		Spiceworks:     Martin9700
		Blog:           www.thesurlyadmin.com
		
		Changelog:
			1.1         Modified replace to include the <td> tag, as it was changing the class
                        for the TH row as well.
            1.0         Initial function release
	.LINK
		http://community.spiceworks.com/scripts/show/1745-set-alternatingrows-function-modify-your-html-table-to-have-alternating-row-colors
    .LINK
        http://thesurlyadmin.com/2013/01/21/how-to-create-html-reports/
	#>
    [CmdletBinding()]
   	Param(
       	[Parameter(Mandatory,ValueFromPipeline)]
        [string]$Line,
       
   	    [Parameter(Mandatory)]
       	[string]$CSSEvenClass,
       
        [Parameter(Mandatory)]
   	    [string]$CSSOddClass
   	)
	Begin {
		$ClassName = $CSSEvenClass
	}
	Process {
		If ($Line.Contains("<tr><td>"))
		{	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
			If ($ClassName -eq $CSSEvenClass)
			{	$ClassName = $CSSOddClass
			}
			Else
			{	$ClassName = $CSSEvenClass
			}
		}
		Return $Line
	}
}
#---------------------------------------------------------------------------
#функция форсированной остановки сервиса в случае его подвисания (stop pending и пр.). 
function Stop-PendingService {
 

 
    $Services = Get-WmiObject -Class win32_service -Filter "state = 'stop pending'"
    if ($Services) {
        foreach ($service in $Services) {
            try {
                Stop-Process -Id $service.processid -Force -PassThru -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message"
            }
        }
    }
    else {
        Write-Output "There are currently no services with a status of 'Stopping'."
    }
}
#---------------------------------------------------------------------------
# получаем информацию из конфигурационного файла
$Path = "\\VM-CO-ADM-01\RotationTasks\Config\$env:COMPUTERNAME.ini"
$in = Get-Content -Path $Path| ConvertFrom-Json
#$in = Get-Content -Path $using:Path| ConvertFrom-Json

# добавляем сборку для работы с архивами. для того чтобы работать с нативным dotNet и не зависеть от версии Posh 
Add-Type -assembly "system.io.compression.filesystem"

#устанавливаем глобальные переменные
$Global:logDir = "$($in.LogsPath)"
$global:logTime = Get-Date -Format 'MM-dd-yyyy_hh:mm:ss'

#----------------------------------------------------------------------------
#Функция dot-sourcing write-log.Замени на import-module. Или сделай автозагружаемый модуль psm1,psd1 (не применил, нет необходимости)
#. C:\scripts\Log_Rotation\Write-log.ps1
#удаление старых журналов об операциях
Get-ChildItem -Path $logdir\$env:computername -Attributes !Directory | Remove-Item  -Confirm:$false -Force -Verbose

#Import-Module C:\scripts\Log_Rotation\Write-log.ps1;
Write-Log -Message "Старт обслуживания для сервера $env:COMPUTERNAME" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Входные данные" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Директории с журналами $($in.SourceData.psobject.Properties.value -join "; ")" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Директория для размещения архивов $($in.destinationData)" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Директория логирования операций $($in.LogsPath+$env:COMPUTERNAME)" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Возраст журналов, которые подлежат архивации $($in.DateTime.CompressAndMoveDataDays) дней" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Возраст архивов, которые подлежат удалению $($in.DateTime.RemoveOldCompressDataDays) дней" -Path "$logdir\$env:computername\$env:computername.log"
#----------------------------------------------------------------------------
#Блок остановки сервисов 

$services = $in.Services.psobject.Properties.value
    foreach ($service in $services) 
        {
        
            if (Get-Service $service -ErrorAction SilentlyContinue){
                try {
                Write-Log -Message "Попытка остановить сервис $service" -Path "$logdir\$env:computername\$env:computername.log"
                #&net stop $service
                get-wmiobject win32_service -filter "name=`'$service`'" | Invoke-WmiMethod -Name StopService 
                #$LASTEXITCODE -eq "0"
                if ($? -eq "true") { 
                #stop-service $service -passthru; #stop-service $service.DependentServices -passthru
                Write-Log -Message "$service остановлен" -Path "$logdir\$env:computername\$env:computername.log"}
                else {Write-Log -Message "Внимание! $service не остановлен" -Path "$logdir\$env:computername\$env:computername.log" -Level Error}
                }
            catch {Write-Log -Message "$($Error[0].Exception)" -Path "$logdir\$env:computername\$env:computername.log" -Level Error -ErrorAction Continue}


            }#EO If
        }
#----------------------------------------------------------------------------
#Блок остановки процессов
$processes = $in.processes.psobject.Properties.value
    Foreach ($process in $processes) 
        {
           if (Get-Process -Name $process)
                {
                    try {
                    Write-Log -Message "Попытка остановить процесс $process" -Path "$logdir\$env:computername\$env:computername.log" -Level Warn
                    stop-process -Name $process -Force ;
                    }
                    catch {Write-Log -Message "$($Error[0].Exception)" -Path "$logdir\$env:computername\$env:computername.log" -Level Error -ErrorAction Continue}
                }#EO If
            
        }#EO Foreach


#----------------------------------------------------------------------------
#Блок архивирования  и перемещения файлов

#Время в днях. Журналы старше этого времени будут заархивированы и перенесены в отдельную директорию для архивов
$Compressdays = [int]$($in.DateTime.CompressAndMoveDataDays) 
#Журналы, которые соответствуют времени $Compressdays
$SourceData = $in.SourceData.psobject.Properties.value
$archDir = $($in.DestinationData);

[Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" )
$ExcludeBaseDirectory = $false
$compressionLevel= [System.IO.Compression.CompressionLevel]::Optimal

    Foreach ($SourceEntity in $SourceData) {
        Write-log -Message "Работаем с папкой $SourceEntity" -Path "$logdir\$env:computername\$env:computername.log"
        $Compressdata = Get-ChildItem -Recurse -Path $SourceEntity -Attributes !Directory -Filter *.log  | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$compressdays)}
        Foreach ($origfile in $Compressdata)
            {
            $ParentDirectoryName = $origfile.DirectoryName;
            $OrigFileName = $origfile.name;
            $LastWriteTime = $origfile.LastWriteTime;
            #$ZIPDirectoryName = $archDir+"\"+(Split-path $ParentDirectoryName -Leaf)
            $ZIPDirectoryName = $archDir+(Split-path $ParentDirectoryName -NoQualifier)
            $ZipFileName = $OrigFileName.Replace('.log','.zip')
            Write-log -Message "Архивируем данные из папки $ParentDirectoryName в архив $($ZIPDirectoryName+".zip")" -Path "$logdir\$env:computername\$env:computername.log"
            $ZIPParentDirectoryName = Split-Path $ZIPDirectoryName -Parent
            if (-not(Test-Path $ZIPParentDirectoryName)) {New-Item -Path $ZIPParentDirectoryName -ItemType Directory}
            
            [System.IO.Compression.ZipFile]::CreateFromDirectory($ParentDirectoryName, "$ZIPDirectoryName.zip",$compressionLevel,$ExcludeBaseDirectory)
            Write-log -Message "Удаляем заархивированные старые журналы $($origfile.FullName)" -Path "$logdir\$env:computername\$env:computername.log"
            Remove-Item $origfile.FullName -Force -ErrorAction stop 
            }

        }#EO Foreach

#--------------------------------------------------------------------------------

#Блок удаления старых архивов
#Время в днях. Архивы старше этого времени будут удалены
$ArchiveDays = [int]$($in.DateTime.RemoveOldCompressDataDays) + [int]$($in.DateTime.CompressAndMoveDataDays);
#Архивы, которые будут удалены
$Archivedata = Get-ChildItem -Recurse -Path $archDir -Attributes !Directory -Filter *.zip  | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$ArchiveDays)}      
    Foreach ($archiveFile in  $ArchiveData)
        {
        $Archivename = $($archiveFile.name) #gets the filename
        $Archivedirectory = $($archiveFile.DirectoryName) #gets the directory name
        Write-Log -Message "Удаляем старые архивы $($archiveFile.fullname)  $ArchiveDays-дневной давности" -Path "$logdir\$env:computername\$env:computername.log" -Level Warn
        Remove-Item -path $($archiveFile.fullname) -Force 

        }


#----------------------------------------------------------------------------
#Блок выполнения команд для обслуживания (подумай, нужен ли и где его разместить). 

$Commandsets = $in.Commands.psobject.Properties.value
    Foreach ($Commandset in $commandsets)
         {
            If ($commandset.switch -eq "yes") 
               {
               Write-Log -Message "Trying to run command `"$($commandset.Command)`" " -Path "$logdir\$env:computername\$env:computername.log" 
                 try {
                       $command =  $($Commandset.Command);
                        #&cmd.exe /c "$command"
                        Write-Log -Message "Command `"$($Commandset.Command)`" was completed successfully " -Path "$logdir\$env:computername\$env:computername.log"
                     }
                 catch {Write-Log -Message "$($Error[0].Exception)" -Path "$logdir\$env:computername\$env:computername.log" -Level Error -ErrorAction Continue}
               }#EO If
                    else {continue;}
         }#EO Foreach
#--------------------------------------------------------------------------------
#Блок запуска сервисов 
          
$services = $in.Services.psobject.Properties.value
#$services = $in.Services | Get-Member -MemberType NoteProperty | Select -ExpandProperty definition
    foreach ($service in $services) 
        {
        #$servicename = $($service -split "=")[1]
            if (Get-Service $service -ErrorAction SilentlyContinue){
                try {
                Write-Log -Message "Попытка запуска сервиса $service" -Path "$logdir\$env:computername\$env:computername.log"
                #&net start $servicename
                get-wmiobject win32_service -filter "name=`'$service`'" | Invoke-WmiMethod -Name StartService 
                #start-service $servicename -passthru;start-service $servicename.DependentServices -passthru
                Write-Log -Message "$service запущен" -Path "$logdir\$env:computername\$env:computername.log"
                }
            catch {Write-Log -Message "$($Error[0].Exception)" -Path "$logdir\$env:computername\$env:computername.log" -Level Error}


            }#EO If
        }#EO Foreach
#--------------------------------------------------------------------------------
#блок отправки уведомлений по эл. почте
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #758196;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>
Title of my Report
</title>
"@

$Pre = "<b>Журнал обслуживания логов для сервера $env:computername - $(get-date)</b>"
#--------------------------------------------------------------------------------
#Преобразование log в html
$SourceFile = "$logdir\$env:computername\$env:computername.log"
$TargetFile = "$logdir\$env:computername\$env:computername.htm"

$File = Get-Content $SourceFile
$FileLine = @();
Foreach ($Line in $File) {
 $MyObject = New-Object -TypeName PSObject
 Add-Member -InputObject $MyObject -Type NoteProperty -Name Log -Value $Line
 $FileLine += $MyObject
}
$FileLine |  ConvertTo-Html -Head $Header -PreContent $Pre | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd | Out-File $TargetFile

$content = Get-Content "$logdir\$env:computername\$env:computername.htm"
#--------------------------------------------------------------------------------

$attach = Get-Item "$logdir\$env:computername\$env:computername.log"
#Send mail
$smtpServer = "vm-co-mail-01.exportcenter.ru"
$smtpFrom = "Infrastructure_admin@exportcenter.ru"
$smtpTo = $($in.Recipients.Recipient1);
$copyto = $($in.Recipients.Recipient2);
$messageSubject = "Ротация логов $env:computername"
$body=@"

$content
"@ 
$body= "<pre>" + $body | Out-String -Width 4096
#if ($content.Length -le 18) {Write-Host "file is empty"}
#else {
Send-MailMessage -SmtpServer $smtpserver -To $smtpto -From $smtpfrom -cc $copyto -Encoding "Unicode" -Subject $messageSubject -Body $body  -BodyAsHtml  -ErrorAction SilentlyContinue -Attachments $attach
#}

#---------------------------------------------------------------------------------
#Удаление старых log и htm (на будущее)
$Old_Output_logs=  Get-ChildItem  $logdir\$env:computername -Attributes !Directory | Where-Object -FilterScript {$_.LastWriteTime -lt (get-date).AddDays(-7)} 
$Old_Output_logs | Remove-Item  -Confirm:$false -Force -Verbose
