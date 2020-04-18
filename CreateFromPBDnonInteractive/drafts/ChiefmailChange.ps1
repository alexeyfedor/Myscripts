   $chiefmail = read-host "Enter chiefemail"
   
   $DestFolder = "C:\WorkSet"
   if (!(Test-Path $DestFolder\veryimportantchiefs.csv)) {Copy-Item C:\!!!\veryimportantchiefs.csv -Destination $DestFolder\veryimportantchiefs.csv -Force}

   $inputdata=@();
   $inputdata = import-csv $DestFolder\veryimportantchiefs.csv


   <#
   foreach ($entry in $inputdata)
        {
            if ($entry.chiefs -like $chiefmail) {$chiefmail = [string]$($entry.notchiefs)}
        }
   $chiefmail
   #>

   foreach ($entry in $inputdata) {
            switch ($chiefmail) 
             {  
              "$($entry.chiefs)" {$chiefmail = [string]$($entry.notchiefs)}
              default {$chiefmail = $chiefmail}

            }
   }
   $chiefmail