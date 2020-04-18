# создаем папку для скриптов на удаленном сервере
$comp = 'vm-co-ins-02'
$copyscript = {
$targetscriptfolder = 'c:\scripts'
$Moduletargetscriptfolder ='C:\Windows\System32\WindowsPowerShell\v1.0\Modules\microsoft.powershell.archive.1.2.2'
if (-not(Test-Path $targetscriptfolder)) {New-Item -Path $targetscriptfolder -ItemType Directory}
if (-not(Test-Path $Moduletargetscriptfolder)) {New-Item -Path $Moduletargetscriptfolder -ItemType Directory -Force}

}

Invoke-Command  -ScriptBlock $copyscript -ComputerName  $comp

#------------------------------------------------------------------------------------------------------
#копируем в папку рабочий скрипт  и модуль для архивации
$scriptitem = get-Item "C:\scripts\Log_Rotation\AdInsure\Adisure_common_v3.ps1"
$session = New-PSSession -ComputerName $comp;
$targetscriptfolder = 'c:\scripts';
$Moduletargetscriptfolder ='C:\Windows\System32\WindowsPowerShell\v1.0\Modules\microsoft.powershell.archive.1.2.2'

Copy-Item -Path $scriptitem -ToSession $session -Destination "$targetscriptfolder\Adisure_common_v3.ps1"  -Force

Get-ChildItem -Path "C:\scripts\Modules\microsoft.powershell.archive.1.2.2" -Recurse | ForEach-Object {Copy-Item -path $($PSItem.FullName) -ToSession $session -Destination "$Moduletargetscriptfolder\$($PSItem.name)" -Force }

Remove-PSSession $session 
#------------------------------------------------------------------------------------------------------

#запускаем задание. после выполнения, удаляем
$password = Get-Content "C:\windows\temp\p2.txt" | ConvertTo-SecureString
#$cred = New-Object System.Management.Automation.PSCredential("exportcenter\adm_fedorenko",$password)
$UserName = "exportcenter\adm_fedorenko"
$Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $password
$Pass = $Credentials.GetNetworkCredential().Password 


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

$null = schtasks.exe /create /S  $hostname1 /RU exportcenter\adm_fedorenko /RP $Using:Pass  /TN $taskName /ST $time /SC DAILY /SD $startDate /RL HIGHEST /TR "powershell.exe & `"C:\scripts\Adisure_common_v3.ps1;exit`""

#$null = schtasks.exe /create /S  $hostname1 /RU "SYSTEM" /TN $taskName /ST $time /SC DAILY /SD $startDate /RL HIGHEST /TR "powershell.exe & `"C:\scripts\draft_for_scheduler_v9.ps1;exit`""
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






