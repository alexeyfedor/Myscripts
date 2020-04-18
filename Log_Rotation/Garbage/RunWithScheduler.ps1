# создаем папку для скриптов на удаленном сервере
$comp = 'vm-co-sccm-01'
$copyscript = {
$targetscriptfolder = 'c:\scripts'
if (-not(Test-Path $targetscriptfolder)) {New-Item -Path $targetscriptfolder -ItemType Directory}
}

Invoke-Command  -ScriptBlock $copyscript -ComputerName  $comp

#------------------------------------------------------------------------------------------------------
#копируем в папку рабочий скрипт
$scriptitem = get-Item "C:\scripts\Log_Rotation\draft_for_scheduler_v9.ps1"

$session = New-PSSession -ComputerName $comp;
$targetscriptfolder = 'c:\scripts';
Copy-Item -Path $scriptitem -ToSession $session -Destination "$targetscriptfolder\draft_for_scheduler_v9.ps1"  

Remove-PSSession $session 
#------------------------------------------------------------------------------------------------------

#запускаем задание. после выполнения, удаляем

$runscript = {
$taskName = "LogsRotationTask"
$time = ((get-date).AddMinutes(1)).ToString("hh:mm")
$startDate = (get-date).ToString("dd/MM/yyyy")
$hostname1=$env:COMPUTERNAME;
$targetscriptfolder = 'c:\scripts'

# Создаем ComObject для работы с Task Scheduler
$sch = New-Object -ComObject Schedule.Service
$sch.Connect()
# Корневая директория для заданий
$taskdir = $sch.GetFolder("\")
		
				
# Создаем задачу в 
#$null = schtasks.exe /create /TN $tn /ST 00:00 /RU $user /SC ONCE /TR $cmd /f 2>&1
#$null = schtasks.exe /create /S  $hostname1 /RU exportcenter\adm_fedorenko /RP Фантики   /TN $taskName /ST $time /SC DAILY /SD $startDate /RL HIGHEST /TR "powershell.exe & `"C:\scripts\Log_Rotation\draft_for_scheduler_v8.ps1;exit`""
$null = schtasks.exe /create /S  $hostname1 /RU exportcenter\adm_fedorenko /RP phantiki  /TN $taskName /ST $time /SC DAILY /SD $startDate /RL HIGHEST /TR "powershell.exe & `"C:\scripts\draft_for_scheduler_v9.ps1;exit`""
# Запускаем задачу
$null = $taskdir.GetTask($taskName).Run($null)
			
# Проверим завершение задачи независимо от локализации ОС
$maxcount = 0
While($taskdir.GetTask($taskName).State -ne 3 -and $maxcount -lt 60) {
$maxcount++
Start-Sleep -Sec 1
	}
				
# Получаем результат
#Import-CliXML $logdir\*.xml | Add-Member -Type NoteProperty -Name User -Value $user -PassThru
				
#Удаляем временную задачу и файлы
#Remove-Item -Path $logdir -Force -Recurse -ErrorAction SilentlyContinue
$null = $taskdir.DeleteTask($taskName,0)
		
	}
		
Invoke-Command  -ScriptBlock $runscript -ComputerName $comp  



