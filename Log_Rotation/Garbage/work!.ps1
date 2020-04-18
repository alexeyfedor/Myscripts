$ErrorActionPreference = Stop
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
            $ZIPDirectoryName = $archDir+"\"+(Split-path $ParentDirectoryName -Leaf)
            $ZipFileName = $OrigFileName.Replace('.log','.zip')
            Write-log -Message "Архивируем данные из папки $ParentDirectoryName в архив $($ZIPDirectoryName+".zip")" -Path "$logdir\$env:computername\$env:computername.log"

            #if (-not(Test-Path $ZIPDirectoryName)) {New-Item -Path $ZIPDirectoryName -ItemType Directory}
            
            [System.IO.Compression.ZipFile]::CreateFromDirectory($ParentDirectoryName, "$ZIPDirectoryName.zip",$compressionLevel,$ExcludeBaseDirectory)
            Write-log -Message "Удаляем Заархивированные старые журналы $($origfile.FullName)" -Path "$logdir\$env:computername\$env:computername.log"
            Remove-Item $origfile.FullName -Force -ErrorAction stop
            }

        }#EO Foreach

        


#Блок удаления старых архивов
#Время в днях. Архивы старше этого времени будут удалены
$ArchiveDays = [int]$($in.DateTime.RemoveOldCompressDataDays) + [int]$($in.DateTime.CompressAndMoveDataDays);
#Архивы, которые будут удалены
$Archivedata = Get-ChildItem -Recurse -Path $archDir -Attributes !Directory -Filter *.zip  | Where-Object -FilterScript {$_.LastWriteTime -lt (Get-Date).AddDays(-$ArchiveDays)}      
    Foreach ($archiveFile in  $ArchiveData)
        {
        $Archivename = $($archiveFile.name) #gets the filename
        $Archivedirectory = $($archiveFile.DirectoryName) #gets the directory name
        Write-Log -Message "Удаляем старые архивы $($archiveFile.fullname)  $ArchiveDays давности из $Archivedirectory" -Path "$logdir\$env:computername\$env:computername.log" -Level Warn
        Remove-Item -path $($archiveFile.fullname) -Force

        }










        
        
        
   