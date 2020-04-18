# подготовка входного файла конфигурации
If (-not(Test-Path "c:\temp1")) {New-Item -Path "c:\temp1" -ItemType Container }
$Path = "C:\temp1\$env:COMPUTERNAME.ini"
$Data = @{
    ServerName = "$env:COMPUTERNAME"
    SourceData = @{
        SourcePath1 = 'c:\input1'
        SourcePath2  = 'c:\input2'
    }
    DestinationData = "\\$env:COMPUTERNAME\output"
    LogsPath = "\\$env:COMPUTERNAME\output\logs"
    DateTime =@{
        CompressAndMoveDataDays = '10'
        RemoveOldCompressDataDays = '5'
        RemoveOldLoggingDays = '15'
    }
    CompressionLevel = @{
        Default = 'Optimal'
        Low = 'Fastest'
    }

}|ConvertTo-Json | set-Content -Path $Path -Force

# получаем данные из файла конфигурации
$in = Get-Content -Path $Path | ConvertFrom-Json








<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Rotate-Logs
{
    [CmdletBinding()]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string]$Server,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=1)]
        [string]$SourceData,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=2)]
        [string]$DestinationData,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=3)]
        [string]$LogsPath,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=4)]
        [string]$CompressAndMoveDataDays,
        
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=4)]
        [string]$RemoveOldCompressDataDays,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=5)]
        [string]$RemoveOldLoggingDays,

         [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=5)]
        [string]$CompressionLevel
    )

    Begin
    {
        $tn = "Log Rotation"
		# Папка для временного файла
		$Path = "C:\temp1\$env:COMPUTERNAME.ini"
        $in = Get-Content -Path $Path | ConvertFrom-Json
        #$PSBoundParameters
    }
    Process
    {
    $myarg = '&{}'
    $items = Get-ChildItem -Path "$($in.SourceData.SourcePath1)" -Include *.log;If ($items) {foreach ($item in $items) {Compress-Archive $item.fullpath -CompressionLevel Optimal -DestinationPath $in.DestinationData} }
    $arg = '&{{New-Item -Path {0} -Type Directory -Force;Get-WmiObject Win32_MappedLogicalDisk | Export-Clixml {0}\$env:UserName.xml}}' -f $logdir
	

    $cmd = 'powershell.exe -WindowStyle Hidden -NoProfile -NoLogo -Command {0}' -f $arg

    }
    End
    {
    }
}
