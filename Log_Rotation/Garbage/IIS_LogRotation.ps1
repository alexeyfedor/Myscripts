# log rotations

#----------------------------------------------------------
# указать source
# указать Destination
# указать  глубину хранения
# рестарт сервисов


Get-ChildItem -Path 'C:\inetpub\logs\LogFiles\*' -Include *.log -Recurse | Where-Object {$_.LastWriteTime -le [datetime]::Today.AddDays(-30)} | Remove-Item -Confirm:$false
Get-ChildItem -Path 'C:\Program Files\Microsoft\Exchange Server\V15\Logging\*' -Include *.log -Recurse | Where-Object {$_.LastWriteTime -le [datetime]::Today.AddDays(-30)} | Remove-Item -Confirm:$false
Get-ChildItem -Path 'C:\Program Files\Microsoft\Exchange Server\V15\TransportRoles\Logs\*' -Include *.log -Recurse | Remove-Item -Confirm:$false




#----------------------------------------------------------
<#
$LogPath = "C:\inetpub\logs" 
$maxDaystoKeep = -30 
$outputPath = "c:\CleanupTask\Cleanup_Old_logs.log" 
  
$itemsToDelete = dir $LogPath -Recurse -File *.log | Where LastWriteTime -lt ((get-date).AddDays($maxDaystoKeep)) 
  
if ($itemsToDelete.Count -gt 0){ 
    ForEach ($item in $itemsToDelete){ 
        "$($item.BaseName) is older than $((get-date).AddDays($maxDaystoKeep)) and will be deleted" | Add-Content $outputPath 
        Get-item $item | Remove-Item -Verbose 
    } 
} 
ELSE{ 
    "No items to be deleted today $($(Get-Date).DateTime)"  | Add-Content $outputPath 
    } 
   
Write-Output "Cleanup of log files older than $((get-date).AddDays($maxDaystoKeep)) completed..." 
start-sleep -Seconds 10





#>


#The following Powershell script will loop through websites and it's configured log folders and delete files which are older that one week

<#

Import-Module WebAdministration  
  
#Maximum age in days of files to be deleted  
$logfileMaxAge = 7  
foreach($website in $(Get-Website))  
{  
    #Get log folder for current website  
    $folder="$($website.logFile.directory)\W3SVC$($website.id)".replace("%SystemDrive%",$env:SystemDrive)  
    #Get all log files in the folder  
    $files = Get-ChildItem $folder -Filter *.log  
  
    foreach($file in $files){  
        if($file.LastWriteTime -lt (Get-Date).AddDays(-1*$logfileMaxAge)){  
            #Remove fie older than logfileMaxAge days  
            Remove-Item $file.FullName  
  
        }  
    }  
}  




#>

#I had the same issue, so I wrote a Powershell which will setup ScheduledTask which executes another Powershell script. Use previous script and save it to any place on the disk. I placed it at D:\PowershellScripts\IISLogCleanup.ps1 which I also used in the next sample as a parameter for scheduled task:
<#
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument 'D:\PowershellScripts\IISLogCleanup.ps1'  
$trigger = New-ScheduledTaskTrigger -Daily -At 3am  
$prncipal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest  
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $prncipal -TaskName "IIS Log Cleanup" -Description "Daily clean up of IIS logs" 
#>


<#

set-location c:\windows\system32\Logfiles\W3SVC1\ -ErrorAction Stop
foreach ($File in get-childitem -include *.log) {
   if ($File.LastWriteTime -lt (Get-Date).AddDays(-30)) {
      del $File
   }
}

#>




Set-Executionpolicy RemoteSigned -Force
$days=20 #You can change the number of days here
 
$IISLogPath="C:\inetpub\logs\LogFiles\"
$ExchangeLoggingPath="C:\Program Files\Microsoft\Exchange Server\V15\Logging\"
$WindowsTemp="C:\Windows\Temp\"
 
Write-Host "Removing IIS, TMP_ and Exchange logs; keeping last" $days "days"
Function CleanTmpFiles($TargetFolder)
{
    Write-Host "Deleting tmp_* files and folders in $TargetFolder" 
    Get-ChildItem $TargetFolder -Include tmp_* -Recurse -ErrorAction SilentlyContinue | foreach ($_) {Remove-Item $_.FullName -Recurse -ErrorAction SilentlyContinue}
}
Function CleanLogfiles($TargetFolder)
{
    if (Test-Path $TargetFolder) {
        $Now = Get-Date
        $LastWrite = $Now.AddDays(-$days)
        $Files = Get-ChildItem $TargetFolder -Include *.log -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
        foreach ($File in $Files)
            {Write-Host "Deleting file $File" -ForegroundColor "Red"; Remove-Item $File -ErrorAction SilentlyContinue | out-null}
       }
Else {
    Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "red"
    }
}
 
CleanLogfiles($IISLogPath)
CleanLogfiles($ExchangeLoggingPath)
CleanTmpFiles($WindowsTemp)
