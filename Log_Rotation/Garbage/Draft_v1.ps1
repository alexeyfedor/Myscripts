








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
    function Rotation-Logs
    {
        [CmdletBinding()]
        
        
        Param
        (
             # Server Name
            [Parameter(Mandatory=$False,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true,
                       Position=0)]
            [string]$ServerName,
            # Data source
            [Parameter(Mandatory=$true,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true,
                       Position=1)]
            [string]$SourceData,
    
            # Data Destination
            [Parameter(Mandatory=$true,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true,
                       Position=2)]
            [string]$DestinationData,

            # Operations Logs target
            [Parameter(Mandatory=$true,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true,
                       Position=3)]
            [string]$DestinationLogs,
            
            # Archive switch. If $true, data archive and move to Data Destination. If $false it only delete data
            [Parameter(Mandatory=$false,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true
                       )]
            [bool]$CompressEnable,

            # Data that need to compress and move to destination
            [Parameter(Mandatory=$true,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true
                       )]
            [int]$CompressAndMoveDataFromSourceDays,

              # How long in days to retain audit logs
            [Parameter(Mandatory=$true,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true
                       )]
            [int]$RemoveCompressFromDestinationDays,

            # How long in days to retain Data in Destination
            [Parameter(Mandatory=$false,
                       ValueFromPipelineByPropertyName=$true,
                       ValueFromPipeline=$true
                       )]
            [int]$RemoveAuditLogsDays

             
        )
    
       begin
       {
       #copy ini file to destination server
        $Now = $((get-date).tostring("dd.MM.yy-hh:mm:ss"))
        #$ServerName = $env:COMPUTERNAME;
        $path = "C:\Rotation\$ServerName.ini" 
 
 switch -Regex -File $path
    {
        'SourceDataCatalog'
            {
                $sourceData =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
        'DestinationDataCatalog'
            {
                $DestinationData =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
       'DestinationLogs'
            {
                $DestinationLogs =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
        'CompressEnable'
            {
                $CompressEnable =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
        'CompressAndMoveDataFromSourceDays'
            {
                $CompressAndMoveDataFromSourceDays =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }

        'CompressAndMoveDataFromSourceDays'
            {
                $CompressAndMoveDataFromSourceDays =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
        'RemoveCompressFromDestinationDays'
            {
                $RemoveCompressFromDestinationDays =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
        'RemoveAuditLogsDays'
            {
                $RemoveAuditLogsDays =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
        'ServiceName1'
            {
                $ServiceName1 =  ($PSItem -split "=" -replace ";" -replace "\s")[1]
            }
    }# EO switch 
       }
        
        
        Process
        {
            if (Test-Path $SourceData) 
                {
                $Files = Get-ChildItem $SourceData -Include *.log -Recurse | Where {$_.LastWriteTime -le (get-date).AddDays(-$CompressAndMoveDataFromSourceDays)}
            
                }
            else 
                {
                    Write-Warning -Message "The folder $SourceData doesn't exist! Check the folder path!"
                }

        }
        
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