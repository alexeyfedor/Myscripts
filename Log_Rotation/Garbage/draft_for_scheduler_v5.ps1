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

#Подготовка данных для сервера (Запускается на сервере). Подумай, как сделать централизовано
$new_date = (Get-Date -Format 'MM-dd-yyyy_hh:mm:ss')
#сетевой ресурс для сбора конфигурационных файлов для задачи ротации логов
$Path = "\\VM-CO-ADM-01\RotationTasks\Config\$env:COMPUTERNAME.ini"
#Создаем хэш таблицу для каждого из серверов и экспортируем ее в конфигурационный файл
<#$Data = @{
    ServerName = "$env:COMPUTERNAME"
    SourceData = 'C:\InetLogs\Logs\LogFiles'
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

}|ConvertTo-Json | set-Content -Path $Path -Force
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
# получаем информацию из конфигурационного файла
$Path = "\\VM-CO-ADM-01\RotationTasks\Config\$env:COMPUTERNAME.ini"
$in = Get-Content -Path $Path| ConvertFrom-Json
#$in = Get-Content -Path $using:Path| ConvertFrom-Json
 

#устанавливаем глобальные переменные

$Global:SourceDir = "$($in.SourceData)" #Location of source logs
$Global:archDir = "$($in.DestinationData)" #archive directory location
$Global:logDir = "$($in.LogsPath)"
$global:logTime = Get-Date -Format 'MM-dd-yyyy_hh:mm:ss'

#----------------------------------------------------------------------------
#Функция dot-sourcing write-log.Замени на import-module. Или сделай автозагружаемый модуль psm1,psd1 (не применил, нет необходимости)
#. C:\scripts\Log_Rotation\Write-log.ps1
#Import-Module C:\scripts\Log_Rotation\Write-log.ps1;
Write-Log -Message "Starting log for $env:COMPUTERNAME" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Config Operations" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Source directory $($in.SourceData)" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Destination directory $($in.DestinationData)" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Log directory $($in.LogsPath)" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "Logs to archive age $($in.DateTime.CompressAndMoveDataDays) days" -Path "$logdir\$env:computername\$env:computername.log"
Write-Log -Message "ZIP to remove age $($in.DateTime.RemoveOldCompressDataDays) days" -Path "$logdir\$env:computername\$env:computername.log"
#----------------------------------------------------------------------------
#Блок остановки сервисов и удаления  процессов
  if (Get-Service $($in.Services.Name2) -ErrorAction SilentlyContinue){
    try {  
        Write-Log -Message "Trying to stop $($in.Services.Name2)" -Path "$logdir\$env:computername\$env:computername.log"
        &net stop $($in.Services.Name2)
        Write-Log -Message "$($in.Services.Name2) is stopped" -Path "$logdir\$env:computername\$env:computername.log"
        }
    catch {Write-Log -Message "$Error[0].Exception" -Path "$logdir\$env:computername\$env:computername.log" -Level Error;}
    }#EO if

 if (Get-Service $($in.Services.Name1) -ErrorAction SilentlyContinue){
    try {  
        Write-Log -Message "Trying to stop $($in.Services.Name1)" -Path "$logdir\$env:computername\$env:computername.log"
        &net stop $($in.Services.Name1)
        Write-Log -Message "$($in.Services.Name1) is stopped" -Path "$logdir\$env:computername\$env:computername.log"
        }
    catch {Write-Log -Message "$Error[0].Exception" -Path "$logdir\$env:computername\$env:computername.log" -Level Error;}  
    }#EO if
 
 if (Get-Service $($in.Services.Name3) -ErrorAction SilentlyContinue){
    try {  
        Write-Log -Message "Trying to stop $($in.Services.Name3)" -Path "$logdir\$env:computername\$env:computername.log"
        &net stop $($in.Services.Name3)
        Write-Log -Message "$($in.Services.Name3) is stopped" -Path "$logdir\$env:computername\$env:computername.log"
        }
    catch {Write-Log -Message "$Error[0].Exception" -Path "$logdir\$env:computername\$env:computername.log" -Level Error;} 
  }#EO if

#----------------------------------------------------------------------------
#Блок архивирования  и перемещения файлов
#Время в днях. Журналы старше этого времени будут заархивированы и перенесены в отдельную директорию для архивов
$Compressdays = [int]$($in.DateTime.CompressAndMoveDataDays) 
#Журналы, которые соответствуют времени $Compressdays
$Compressdata = Get-ChildItem -Recurse -Path $SourceDir -Attributes !Directory -Filter *.log  | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$compressdays)}


Write-Log -Message "Compress and move files with $Compressdays days old " -Path "$logdir\$env:computername\$env:computername.log"
    foreach ($orig_file in $compressdata)

        {
            #сжимаем журналы
            Write-Log -Message "Get the filename and directory" -Path "$logdir\$env:computername\$env:computername.log"
            $Origname = $orig_file.name #gets the filename
            $Origdirectory = $orig_file.DirectoryName #gets the directory name
            Write-Log -Message "File name $($orig_file.name). Parent directory $($orig_file.DirectoryName). Lastwritetime of the file - $($orig_file.LastWriteTime)" -Path "$logdir\$env:computername\$env:computername.log"
            #Write-Log -Message "Gets the lastwritetime of the file - $($orig_file.LastWriteTime)" -Path "$logdir\$env:computername\$env:computername.log" 
            $LastWriteTime = $orig_file.LastWriteTime #gets the lastwritetime of the file
            $zipfile = $Origname.Replace('.log','.zip') #creates the zipped filename
            Write-Log -Message "Compress $($Origdirectory+"\"+$orig_file) to $($archDir+"\"+$zipfile)" -Path "$logdir\$env:computername\$env:computername.log" 
            Compress-Archive "$Origdirectory\$orig_file" -DestinationPath "$archDir\$zipfile" -CompressionLevel Optimal -Update 
            

                #if ($LastExitCode -eq 0) #verifies the zip process was successful

                 #   {
                        # Переопределяем время изменения zip файлов. Делаем, чтобы совпадало с временем оригинального файла;
                        Write-Log -Message "Override last write time of $zipfile file to origin file write time $LastWriteTime" -Path "$logdir\$env:computername\$env:computername.log" 
                        Get-ChildItem $archDir -Filter $zipfile | % {$_.LastWriteTime = $LastWriteTime;}                                                                                
                  #  } 
                        #удаляем обработанные оригинальные файлы
                        Write-Log -Message "Remove origin file $($origdirectory+"\"+$orig_file) with with $Compressdays days old from source directory" -Path "$logdir\$env:computername\$env:computername.log" -Level Warn
                        try {
                                Remove-Item -Path $($origdirectory+"\"+$orig_file) 
                            }
                        catch {Write-Log -Message "$Error[0].Exception" -Path "$logdir\$env:computername\$env:computername.log" -Level Error;}

        }#EO Foreach
#--------------------------------------------------------------------------------
#Блок удаления старых архивов
#Время в днях. Архивы старше этого времени будут удалены
$ArchiveDays = [int]$($in.DateTime.RemoveOldCompressDataDays) + [int]$($in.DateTime.CompressAndMoveDataDays);
#Архивы, которые будут удалены
$Archivedata = Get-ChildItem -Recurse -Path $archDir -Attributes !Directory -Filter *.zip  | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$ArchiveDays)}      

Write-Log -Message "Removes zip archives with $ArchiveDays days old " -Path "$logdir\$env:computername\$env:computername.log"
   #Удаляем старые архивы
   foreach ($archiveFile in  $ArchiveData)
        {
            $Archivename = $($archiveFile.name) #gets the filename
            $Archivedirectory = $($archiveFile.DirectoryName) #gets the directory name
            Write-Log -Message "Remove zip archive $($Archivedirectory+"\"+$archiveFile) with with $ArchiveDays days old from $Archivedirectory" -Path "$logdir\$env:computername\$env:computername.log" -Level Warn
            try {
                    Remove-Item  -path $($Archivedirectory+"\"+$archiveFile)   #deletes the file
                }
            catch {Write-Log -Message "$Error[0].Exception" -Path "$logdir\$env:computername\$env:computername.log" -Level Error;}

        }
#--------------------------------------------------------------------------------
#Блок запуска сервисов 
  if (Get-Service $($in.Services.Name2) -ErrorAction SilentlyContinue){
    try {  
        Write-Log -Message "Trying to start $($in.Services.Name2)" -Path "$logdir\$env:computername\$env:computername.log"
        &net start $($in.Services.Name2)
        Write-Log -Message "$($in.Services.Name2) is started" -Path "$logdir\$env:computername\$env:computername.log"
        }
    catch {Write-Log -Message "$Error[0].Exception" -Path "$logdir\$env:computername\$env:computername.log" -Level Error;}
    }#EO if

  if (Get-Service $($in.Services.Name1) -ErrorAction SilentlyContinue){
    try {  
        Write-Log -Message "Trying to start $($in.Services.Name1)" -Path "$logdir\$env:computername\$env:computername.log"
        &net start $($in.Services.Name1)
        Write-Log -Message "$($in.Services.Name1) is started" -Path "$logdir\$env:computername\$env:computername.log"
        }
    catch {Write-Log -Message "$Error[0].Exception"  -Path "$logdir\$env:computername\$env:computername.log" -Level Error;}
    }#EO if
     
  if (Get-Service $($in.Services.Name3) -ErrorAction SilentlyContinue){
    try {  
        Write-Log -Message "Trying to start $($in.Services.Name3)" -Path "$logdir\$env:computername\$env:computername.log"
        &net start $($in.Services.Name3)
        Write-Log -Message "$($in.Services.Name3) is started" -Path "$logdir\$env:computername\$env:computername.log"
        }
    catch {Write-Log -Message "$Error[0].Exception" -Path "$logdir\$env:computername\$env:computername.log" -Level Error;}
    }#EO if
#--------------------------------------------------------------------------------
#блок отправки уведомлений по эл. почте
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #B1CAF6;}
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
$FileLine = @()
Foreach ($Line in $File) {
 $MyObject = New-Object -TypeName PSObject
 Add-Member -InputObject $MyObject -Type NoteProperty -Name HealthCheck -Value $Line
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

