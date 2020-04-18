#part1. подготовка данных для сервера (запускается на сервере).
# подготовка входного файла конфигурации
#If (-not(Test-Path "c:\$env:COMPUTERNAME")) {New-Item -Path "c:\$env:COMPUTERNAME" -ItemType Container}


$Path = "$env:windir\temp\$env:COMPUTERNAME.ini"
$Data = @{
    ServerName = "$env:COMPUTERNAME"
    SourceData = 'C:\InetLogs\Logs\LogFiles'
    DestinationData = "C:\InetLogs\Logs\LogFiles\Output_data"
    LogsPath = "C:\InetLogs\Logs\LogFiles\output_logs"
    DateTime =@{
        CompressAndMoveDataDays = '10'
        RemoveOldCompressDataDays = '5'
        RemoveOldLoggingDays = '45'
    }
    CompressionLevel = @{
        Default = 'Optimal'
        Low = 'Fastest'
    }

}|ConvertTo-Json | set-Content -Path $Path -Force

# получаем данные из файла конфигурации
$in = Get-Content -Path $Path | ConvertFrom-Json





#Setting Global variables

$Global:SourceDir = "$($in.SourceData)" #Location of IIS logs
$Global:archDir = "$($in.DestinationData)" #archive directory location
$Global:logDir = "$($in.LogsPath)"
$global:logTime = Get-Date -Format 'MM-dd-yyyy_hh:mm:ss'
#$Global:logFile = "$($in.LogsPath)\$logTime.txt"

#Clear-Content $LogFile

#--------------------------------------------------
Function Compress-Logs

    {

        $days = $($in.DateTime.CompressAndMoveDataDays) #this will result in custom days of non-zipped log files
        $data = Get-ChildItem -Recurse -Path $SourceDir -Attributes !Directory -Filter *.log  | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$days)

    }

    foreach ($source_file in $data)

        {

            $name = $source_file.name #gets the filename
            $directory = $source_file.DirectoryName #gets the directory name
            $LastWriteTime = $source_file.LastWriteTime #gets the lastwritetime of the file
            $zipfile = $name.Replace('.log','.zip') #creates the zipped filename
            Compress-Archive "$directory\$name" -DestinationPath "$directory\$zipfile" -CompressionLevel Optimal -Update 

                if ($LastExitCode -eq 0) #verifies the zip process was successful

                    {

                        Get-ChildItem $directory -Filter $zipfile | % {$_.LastWriteTime = $LastWriteTime} #sets the LastWriteTime of the zip file to match the original log file
                        Remove-Item -Path $directory\$name #deletes the original log file
                        $logtime + ': Created archive ' + $directory + '\' + $zipfile + '. Deleted original logfile: ' + $name | Add-Content "$logdir\$logtime_$name.txt" -Encoding UTF8 #writes logfile entry

                    }#EO If

        }#EO Foreach

}#EO Function Compress-Logs









#------------------------------------------

Function Archive-Logs

    {

        
        $ArchiveDays = [int]$($in.DateTime.RemoveOldCompressDataDays) + [int]$($in.DateTime.CompressAndMoveDataDays) #this will provide 7 days of zipped log files in the original directory - all others will be archived
        $CompressFolders = Get-ChildItem -Path $SourceDir -Attributes Directory #gets the folders in the source directory
        $ZipFiles = Get-ChildItem -Recurse -Path $SourceDir -Attributes !Directory -Filter *.zip | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$ArchiveDays)} #gets the zipped logs

            #foreach ($Folder in $CompressFolders)

               # {

                    #$Newfolder = $Folder.name #gets the directory the logfile is in
                    #$Newfolder = $Folder -replace $logdir, '' #removes the original log directory keeping on the child portion of the name .ie c:\wwwlogs\w3svc becomes w3svc – needed for the folder creation and file move portions of this function
                    #$targetDir = $archdir + $folder

                    #    if (!(Test-Path -Path $targetDir -PathType Container))  #checks if the folder exists in the archive location

                    #        {
                    #           New-Item -ItemType directory -Path $targetDir #creates folder if it doesn’t exist
                    #        }#EO If

              #  }#EO foreach

            foreach ($ziplog in $ZipFiles)

                {

                    $origZipDir = $ziplog.DirectoryName #gets the current folder name
                    $fileName = $ziplog.Name #gets the current zipped log name
                    $source = $origZipDir + '\' + $fileName #builds the source data
                    #$destDir = $origZipDir -replace $logdir, '' #removes the parent log folder
                    $destination = $archdir + $destDir + '\' + $fileName #builds the destination data
                    Move-Item $Source -Destination $archdir  #moves the file from the current location to the archive location
                    $logtime + ': Moved archive ' + $source + ' to ' + $destination | Add-Content "$logdir\$logtime_$name.txt" -Encoding UTF8 #creates logfile entry

                }#EO foreach

} # EO function Archive-Logs



#-------------------------------------------------------------------------

Function Delete-Archive {

    $delDays= [int]$($in.DateTime.RemoveOldCompressDataDays) + [int]$($in.DateTime.CompressAndMoveDataDays) + [int]$($in.DateTime.RemoveOldLoggingDays) #retains custom of logs - adjust to meet  retention plan
    #$delDays= "10" #retains custom of logs - adjust to meet  retention plan
    
    $delLogs = Get-ChildItem -Recurse -Path $archdir -Attributes !Directory -Filter *.zip  | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$delDays)} #gets the list of logs older than specified for deletion
        Foreach ($delLog in $delLogs) {

            $filename = $delLog.Name #gets the filename
            $delDir = $delLog.DirectoryName #gets the directory
            $delFile = $delDir+ '\' + $filename #builds the delete data
            Remove-Item $delFile -Force #deletes the file
            $logtime + ': Deleted archive ' + $delfile |Add-Content "$logdir\$logtime_$name.txt" -Encoding UTF8 
            } #EO Foreach

}# EO Function


#--------------------------------------------------------------------------


Compress-Logs

Archive-Logs

Delete-Archive