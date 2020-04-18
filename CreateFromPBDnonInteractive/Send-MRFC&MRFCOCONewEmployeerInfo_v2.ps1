# добавлен файл подстановки e-mail адресов руководителей.лежит в C:\WorkSet\veryimportantchiefs.csv. Копия в c:\!!!\veryimportantchiefs.csv

$FormatEnumerationLimit=-1
$date=(get-date).ToString('dd/MM/yyyy')
$DestFolder = "C:\WorkSet"
$DestFolderHTML = "C:\WorkSet\HTML"
$DestFolderError = "C:\WorkSet\Error"
if (-not (test-path -Path $DestFolder)) {New-Item -ItemType Container $DestFolder}
if (-not (test-path -Path $DestFolderHTML)) {New-Item -ItemType Container $DestFolderHTML}
if (-not (test-path -Path $DestFolderError)) {New-Item -ItemType Container $DestFolderError}
# копируем файлик замены email VIP на email заместителей
if (!(Test-Path $DestFolder\veryimportantchiefs.csv)) {Copy-Item C:\!!!\veryimportantchiefs.csv -Destination $DestFolder\veryimportantchiefs.csv -Force}
#Функция генерации пароля пользователя
function New-SWRandomPassword {
    <#
    .Synopsis
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .DESCRIPTION
       Generates one or more complex passwords designed to fulfill the requirements for Active Directory
    .EXAMPLE
       New-SWRandomPassword
       C&3SX6Kn

       Will generate one password with a length between 8  and 12 chars.
    .EXAMPLE
       New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 12 -Count 4
       7d&5cnaB
       !Bh776T"Fw
       9"C"RxKcY
       %mtM7#9LQ9h

       Will generate four passwords, each with a length of between 8 and 12 chars.
    .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString
    .EXAMPLE
       New-SWRandomPassword -InputStrings abc, ABC, 123 -PasswordLength 4 -FirstChar abcdefghijkmnpqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ
       3ABa

       Generates a password with a length of 4 containing atleast one char from each InputString that will start with a letter from 
       the string specified with the parameter FirstChar
    .OUTPUTS
       [String]
    .NOTES
       Written by Simon Wåhlin, blog.simonw.se
       I take no responsibility for any issues caused by this script.
    .FUNCTIONALITY
       Generates random passwords
    .LINK
       http://blog.simonw.se/powershell-generating-random-password-for-active-directory/
   
    #>
    [CmdletBinding(DefaultParameterSetName='FixedLength',ConfirmImpact='None')]
    [OutputType([String])]
    Param
    (
        # Specifies minimum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({$_ -gt 0})]
        [Alias('Min')] 
        [int]$MinPasswordLength = 8,
        
        # Specifies maximum password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='RandomLength')]
        [ValidateScript({
                if($_ -ge $MinPasswordLength){$true}
                else{Throw 'Max value cannot be lesser than min value.'}})]
        [Alias('Max')]
        [int]$MaxPasswordLength = 12,

        # Specifies a fixed password length
        [Parameter(Mandatory=$false,
                   ParameterSetName='FixedLength')]
        [ValidateRange(1,2147483647)]
        [int]$PasswordLength = 8,
        
        # Specifies an array of strings containing charactergroups from which the password will be generated.
        # At least one char from each group (string) will be used.
        [String[]]$InputStrings = @('abcdefghijkmnpqrstuvwxyz', 'ABCEFGHJKLMNPQRSTUVWXYZ', '23456789', '!"#%&'),

        # Specifies a string containing a character group from which the first character in the password will be generated.
        # Useful for systems which requires first char in password to be alphabetic.
        [String] $FirstChar,
        
        # Specifies number of passwords to generate.
        [ValidateRange(1,2147483647)]
        [int]$Count = 1
    )
    Begin {
        Function Get-Seed{
            # Generate a seed for randomization
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToUInt32($RandomBytes, 0)
        }
    }
    Process {
        For($iteration = 1;$iteration -le $Count; $iteration++){
            $Password = @{}
            # Create char arrays containing groups of possible chars
            [char[][]]$CharGroups = $InputStrings

            # Create char array containing all chars
            $AllChars = $CharGroups | ForEach-Object {[Char[]]$_}

            # Set password length
            if($PSCmdlet.ParameterSetName -eq 'RandomLength')
            {
                if($MinPasswordLength -eq $MaxPasswordLength) {
                    # If password length is set, use set length
                    $PasswordLength = $MinPasswordLength
                }
                else {
                    # Otherwise randomize password length
                    $PasswordLength = ((Get-Seed) % ($MaxPasswordLength + 1 - $MinPasswordLength)) + $MinPasswordLength
                }
            }

            # If FirstChar is defined, randomize first char in password from that string.
            if($PSBoundParameters.ContainsKey('FirstChar')){
                $Password.Add(0,$FirstChar[((Get-Seed) % $FirstChar.Length)])
            }
            # Randomize one char from each group
            Foreach($Group in $CharGroups) {
                if($Password.Count -lt $PasswordLength) {
                    $Index = Get-Seed
                    While ($Password.ContainsKey($Index)){
                        $Index = Get-Seed                        
                    }
                    $Password.Add($Index,$Group[((Get-Seed) % $Group.Count)])
                }
            }

            # Fill out with chars from $AllChars
            for($i=$Password.Count;$i -lt $PasswordLength;$i++) {
                $Index = Get-Seed
                While ($Password.ContainsKey($Index)){
                    $Index = Get-Seed                        
                }
                $Password.Add($Index,$AllChars[((Get-Seed) % $AllChars.Count)])
            }
            Write-Output -InputObject $(-join ($Password.GetEnumerator() | Sort-Object -Property Name | Select-Object -ExpandProperty Value))
        }
    }
}

#dot source для красивого отображения html отчета (меняется цвет бэкграунда  в ячейках таблицы), взял отсюда http://thesurlyadmin.com/2013/01/21/how-to-create-html-reports/
. C:\scripts\Set_alternate_row_for_html.ps1

#заголовки и таблица
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #8DA1C4;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>
Title of my Report
</title>
"@

#$Pre = "<b>Учетные данные для нового работника - $date</b>"
#$Post = "Footer after the report"


#----------------------------------------------------------------------
#получаем данные из ПБД
[string] $Server= "10.31.3.3"
[string] $Database = "DataExchangeDB"
#[string] $SqlQuery= $("SELECT * FROM [DataExchangeDB].[MIMS].[Persons_FULL_and_uvol]  where [company] like '%МРФ `"Центр`" ПАО `"Ростелеком`"%' and [extensionAttribute9] like '%основное место работы%' and ([require_login] like '%Y%' or [lev_grade] ='2' or [lev_grade] ='3')")
[string] $SqlQuery= $("SELECT * FROM [DataExchangeDB].[MIMS].[Persons_FULL_and_uvol]  `
where ([company] like '%МРФ `"Центр`" ПАО `"Ростелеком`"%' or ([company] like '%МФ ОЦО ПАО `"Ростелеком`"%' and ([extensionAttribute11] like '%Воронеж%' or [extensionAttribute11] like '%ярослав%')))`
 and [extensionAttribute9] like '%основное место работы%' and ([require_login] like '%Y%' or [lev_grade] ='2' or [lev_grade] ='3')")
[string] $user = "extreg_MSK_AD"
[string] $pwd = 'm29$05K14ad'
 
$Command = New-Object System.Data.SQLClient.SQLCommand
$Command.Connection = $Connection
 
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = "Server = $Server; uid=$user; pwd=$pwd; Database = $Database; Integrated Security = False;"
 
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = $SqlQuery
$SqlCmd.Connection = $SqlConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet)
 
#$DataSet.Tables[0] | out-file "C:\work3\NewMRFC.csv"
$PayloadData = $DataSet.Tables[0]

# EO get data from DB

#---------------------------------------------------------------------
# default Variable Set

$GC = 'scedr08dc001.ce.rt.ru:3268'
$DC = 'scedr08dc001.ce.rt.ru'

#-----------------------------------------------------------------
#добавляем данные из файла подстановки email в переменную
$inputdata=@();
$inputdata = import-csv $DestFolder\veryimportantchiefs.csv

#-----------------------------------------------------------------

foreach ($Employeer in $PayloadData)
    {
        $ID = $Employeer.EmployeeID
        IF (($Employeer.ASSIGNMENT_START_DATE).ToString("yyyy-MM-dd") -eq (Get-Date).ToString("yyyy-MM-dd"))
            {
                 
            try {
                $Exist_AD_Account = get-aduser -Properties EmployeeID -filter {EmployeeID -eq $ID} -Server $GC
               
                #create set of attrubutes
                     $Nameforexception = $Employeer.CN
                     $Name = $Exist_AD_Account.name
                     $DisplayName = $Exist_AD_Account.name
                     $SAMAcc = $Exist_AD_Account.samaccountname
                     $UPN = $Exist_AD_Account.userprincipalname
                     $Hired_date = ($Employeer.ASSIGNMENT_START_DATE).ToString("yyyy-MM-dd")
                     $Hired_date_for_Email = ($Employeer.ASSIGNMENT_START_DATE).ToString("dd.MM")
                     $Chief = $Employeer.manager
                     $ChiefIO = ([string](($Employeer.manager -split " ")[1,2]))
                     $Address = $Employeer.extensionAttribute11
                     $EmployeeType =$Employeer.employeeType
                     $EmployeeNumber = $Employeer.EmployeeNumber
                     $ChiefMail = [string]$Employeer.mail_chif
                     
                     
                     #перебираем данные из файла и сравниваем e-mail. если есть e-mail VIP, подменяем его
                     foreach ($entry in $inputdata) {
                        switch ($chiefmail)   {  
                            "$($entry.chiefs)" {$chiefmail = [string]$($entry.notchiefs)}
                            default {$chiefmail = $chiefmail}

                            }#EO switch
                    }#EO foreach

                
                $Userpass = New-SWRandomPassword -Count 1 -PasswordLength 8
                $newpwd = (ConvertTo-SecureString -AsPlainText $Userpass -Force)
                #don't change order of operations. Else see to catch block
                Set-aduser -Identity $Exist_AD_Account.DistinguishedName -PasswordNeverExpires $false -Enabled $true -Server $DC -Verbose;
                Set-ADAccountPassword -Identity $Exist_AD_Account.DistinguishedName -NewPassword $newpwd -Reset -Confirm:$false -Server $DC
                Set-ADUser -Identity $Exist_AD_Account.DistinguishedName -ChangePasswordAtLogon $true -Server $DC -Verbose;
                
                $info = "" |select EmployeeID,ФИО,Логин,E-mail,Пароль,'Дата приема',Адрес
                                $info.EmployeeID = $ID;
                                $info.ФИО = $Name;
                                $info.Логин = $SAMAcc;
                                $info.Пароль = $Userpass;
                                $info.'E-mail' = $UPN
                                $info.'Дата приема' = $Hired_date;
                                $info.Адрес = $Address; 
                                #$info | export-csv -Path "$DestFolder\$name.csv" -Encoding UTF8 -NoTypeInformation

                
                $info  | ConvertTo-Html -as list -Head $Header |Out-File "$DestFolderHTML\$name.htm" 
                
                #Import-Csv -Path "$DestFolder\$name.csv" | ConvertTo-Html -Head $Header -PreContent $Pre | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd|Out-File "$DestFolderHTML\$name.htm"
                $content = Get-Content "$DestFolderHTML\$name.htm";
                
                $recipient = $ChiefMail;
                $altrecipients = 'New_Staff_pass@rt.ru';

                #$recipient = 'fedorenko@center.rt.ru';
                #$altrecipients = 'fedorenko@center.rt.ru';
                


                
                $smtpServer = 'sce09ex01','sce09ex02','sce09ex03','sce09ex04','sce09ex05','sce09ex06' |Get-Random
                $smtpFrom = "NewEmployeerScript@rt.ru"
                $messageSubject = "Внимание. Новый работник - $Name"
$body=@"
Здравствуйте $ChiefIO, 
К Вам $Hired_date_for_Email выходит новый сотрудник, огромная просьба в первый день работы передать ему логин и пароль для входа в компьютер:
$content
Заранее огромное спасибо!
"@ 


                $body= "<pre>" + $body | Out-String -Width 4096
                    if ($content.Length -le 18) {Write-Host "file is empty"}
                    else {Send-MailMessage -SmtpServer $smtpserver -From $smtpfrom -To $recipient -cc $altrecipients -Encoding "Unicode" -Subject $messageSubject -Body $body  -BodyAsHtml -ErrorAction SilentlyContinue}


            }
            catch
            {
            "$($error[0]) for User $Nameforexception  with EmployeeID $ID something went wrong. Check html output in $DestFolderHTML and set-aduser block in script " |out-file "$DestFolderError\Send-$Nameforexception.txt" -Force utf8
            }
         
        }#EO IF
        #Else {write-host "User $($Employeer.CN) starting work not today" -ForegroundColor Yellow}

}#EO Foreach

#check email delivery
#'sce09ex01','sce09ex02','sce09ex03','sce09ex04','sce09ex05','sce09ex06' |Get-MessageTrackingLog -Sender 'NewEmployeerScript@rt.ru' -Recipients 'New_Staff_pass@rt.ru' -Start (get-date).AddDays(-1)
#'sce09ex01','sce09ex02','sce09ex03','sce09ex04','sce09ex05','sce09ex06' |Get-MessageTrackingLog -Sender 'NewEmployeerScript@rt.ru' -Recipients 'New_Staff_pass@rt.ru' -Start (get-date).AddDays(-1) | where {$_.eventid -eq "send"}

<#
'SGD02EXN02','sgd02exn01','SGD02EX010.GD.RT.RU','SKS02EXHT1.ks.RT.RU','sce09ex01','sce09ex02','sce09ex03','sce09ex04','sce09ex05','sce09ex06' |`
Get-MessageTrackingLog -Sender 'NewEmployeerScript@rt.ru'  -Start (get-date).AddDays(-2) | where {($_.MessageSubject -match "Внимание. Новый работник - Парамонов Дмитрий Николаевич") -and ($_.eventid -eq "deliver")}|`
sort timestamp |fl

#>


# SIG # Begin signature block
# MIIMqgYJKoZIhvcNAQcCoIIMmzCCDJcCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwRMyIukLYEPYbD7hriF5+pOr
# rqagggozMIID5jCCAs6gAwIBAgIQUbGzQnDUi1iUINHCVBzmSzANBgkqhkiG9w0B
# AQUFADBBMQswCQYDVQQGEwJSVTETMBEGA1UEChMKUm9zdGVsZWNvbTEdMBsGA1UE
# AxMUUm9zdGVsZWNvbSBQb3J0YWwgQ0EwHhcNMTQwMjEzMDgxOTU4WhcNMjQwMjEz
# MDgzODM0WjAyMQswCQYDVQQGEwJSVTETMBEGA1UEChMKUm9zdGVsZWNvbTEOMAwG
# A1UEAxMFSUNBQ0UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCUsfNv
# GzJCDDwGM29K0EHbGFM3YoAFJ7McXItxQrafjak8hZyBn4J0G6Rf6jSVqj0bhxDL
# PkqcVmg82LyQJxau2b78u8KDq7kRqoRDtiDWDSLqdyLJl3BO131qzUkx+/AU1IkW
# 0kkXsN3bOOJKtoDHRFvSjWsS11muXEepIm44+pn8p4PHKvSDznRdaUIxGDQdPNI+
# i2flaeJ6CGDDHpPOKH2A/3prjTIVUY+mwU9mO/WfZq+5RQAs8xaUxLZbBpRirfvi
# ZCZkVCOH8NuLmhoJ1sc6aBEMj8smWuDdJcew7/Ps1bRU1G0MvQSCZcKrnauZAQzO
# 6ySnglUfGvCkFOZ5AgMBAAGjgegwgeUwgYQGA1UdHwR9MHswPKA6oDiGNmh0dHA6
# Ly9la3VjLnJ0LnJ1OjQ0Ny9jcmwvUm9zdGVsZWNvbSUyMFBvcnRhbCUyMENBLmNy
# bDA7oDmgN4Y1aHR0cDovL3J0Y2EuZ2QucnQucnU6NDQ3L1Jvc3RlbGVjb20lMjBQ
# b3J0YWwlMjBDQS5jcmwwDgYDVR0PAQH/BAQDAgGGMB8GA1UdIwQYMBaAFDwTZt8Y
# XeSWBf9kWKMb7ttWlChwMAwGA1UdEwQFMAMBAf8wHQYDVR0OBBYEFBXx9OigBYEm
# hRDbpP/SR9X02X//MA0GCSqGSIb3DQEBBQUAA4IBAQDKaMuImLWZfHuR53GPi/u3
# iivblrpDxyXD7+BUj7VxRxf8NkqEoLtyKAkB22PYKq9YN2U3N8sUvk7EaxhjHAyJ
# 1AfPNskC+o26HRnjNfMh7EyiBQbsAhzYk4lp2txIdu4qxzMb9XQwIL6frIavO9b5
# h6aeVTwA/KxODMAkdm8jC0EWL3zMxxan8CvLfRBJxGpmWWLsZ5hFu6AvNfF5hO8o
# cFIsabwInoz+xPlh64OtIw4ui6a75y0NBiGspDwBwBIKV5v0zYz1JHCW0KHsWtBH
# dl2qUignBCxGSlwWa9oQxfuL8cpz75nxlALlnNMNg9N8FTM+E2FkvSZmtrKIIisa
# MIIGRTCCBS2gAwIBAgIKONaAAgAAAAAMHjANBgkqhkiG9w0BAQsFADAyMQswCQYD
# VQQGEwJSVTETMBEGA1UEChMKUm9zdGVsZWNvbTEOMAwGA1UEAxMFSUNBQ0UwHhcN
# MTcxMDA2MDYzMDAzWhcNMjAxMDA1MDYzMDAzWjCBrzESMBAGCgmSJomT8ixkARkW
# AlJVMRIwEAYKCZImiZPyLGQBGRYCUlQxEjAQBgoJkiaJk/IsZAEZFgJjZTETMBEG
# A1UECxMKTVJGIENlbnRlcjELMAkGA1UECxMCRFIxDjAMBgNVBAsTBVVzZXJzMT8w
# PQYDVQQDDDbQpNC10LTQvtGA0LXQvdC60L4g0JDQu9C10LrRgdC10Lkg0JzQuNGF
# 0LDQudC70L7QstC40YcwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCj
# Lkq1ll8D9d91+CRiESCi5VWNuJLgt9e4xfnF164kzQKi1/9CvMHgEFDLnCsoh64t
# xLgtkkW2kQ1OW76Hjcdx8WlvN91lME/5CPD9qSKdjKuTA+GURBquxV0ycALGxqQD
# mDl/VPeBc2i2Df5a0aMzJX+XBQJiGOTnN4XFwUpEgft8gCOwJQ3j2wYT+IgntnKc
# 8h+VkRfV6qFk3m3c3o6btETEZd8cWkOTCxKcWQAmCZKnut3nmdlarfPbBVqrNAx1
# ZcgCMJMSvh15I7mVkc3MrrQCdrEH01CmPbifNgOuxQRaF9VZ5WJPUJscvTQLBU0N
# BqnrjZ6wxcLUS2mmkFHNAgMBAAGjggLdMIIC2TA7BgkrBgEEAYI3FQcELjAsBiQr
# BgEEAYI3FQie+heF+cpwg+mXI4XT0A7+zyAwguigGIbzp14CAWQCAQQwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwCwYDVR0PBAQDAgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYI
# KwYBBQUHAwMwHQYDVR0OBBYEFGymBJSpY4PsVTt7sFjqPzOzTlDzMB8GA1UdIwQY
# MBaAFBXx9OigBYEmhRDbpP/SR9X02X//MIHsBgNVHR8EgeQwgeEwgd6ggduggdiG
# gatsZGFwOi8vL0NOPUlDQUNFLENOPVNDRURSMDdDQTAwMSxDTj1DRFAsQ049UHVi
# bGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlv
# bixEQz1SVCxEQz1SVT9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnSGKGh0dHA6Ly9wa2lwcC5jZS5y
# dC5ydS9DZXJ0RGF0YS9JQ0FDRS5jcmwwgf0GCCsGAQUFBwEBBIHwMIHtMIGeBggr
# BgEFBQcwAoaBkWxkYXA6Ly8vQ049SUNBQ0UsQ049QUlBLENOPVB1YmxpYyUyMEtl
# eSUyMFNlcnZpY2VzLENOPVNlcnZpY2VzLENOPUNvbmZpZ3VyYXRpb24sREM9UlQs
# REM9UlU/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRp
# b25BdXRob3JpdHkwSgYIKwYBBQUHMAKGPmh0dHA6Ly9wa2lwcC5jZS5ydC5ydS9D
# ZXJ0RGF0YS9TQ0VEUjA3Q0EwMDEuY2UuUlQuUlVfSUNBQ0UuY3J0MCwGA1UdEQQl
# MCOgIQYKKwYBBAGCNxQCA6ATDBFBX0ZlZG9yZW5rb0BSVC5SVTANBgkqhkiG9w0B
# AQsFAAOCAQEAED+hKTw6ENvNf0+GxbCHFLoVk4L6OLQewd4X/FndgvN4JkTH71V3
# MCiUz5yG9fISyzlO8Xz7X5sbHxW6cmoG6ST6DisS55JMbqRLZ1hwRhEzlwAe562t
# Apamk14W/s/t3qfUHwiSWOUqEpRKDQn3fRX2RXNnzDpvKVx34SeixkK9sWEAbk5w
# AB4D7tlLVVsBmJFcdmcWCjpaBGAa8TOIrIzmbIAW3fggUMfwdrRLwqr2CsrobILd
# 7GzYcgKZ3uDzoxq9lIswiTXkQeuXqRiYoEPIhe0swJDH01XigUNDB+e5khs6K88c
# EMckM5v95ajE+2bjpqx4pbE6pf3WKXegszGCAeEwggHdAgEBMEAwMjELMAkGA1UE
# BhMCUlUxEzARBgNVBAoTClJvc3RlbGVjb20xDjAMBgNVBAMTBUlDQUNFAgo41oAC
# AAAAAAweMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkG
# CSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSfUPHv22/MPLA3SNk5MU01LPB67TANBgkq
# hkiG9w0BAQEFAASCAQAjRnHHNPOXG+eEMGgWRTw642Ab9boFpLlh5C7ay4wrdeJl
# 4lQQcPhXILSEV3JBYnfKannLfMGNCxJqfdDA+94tTYwpPLCd1T23J3h55gjDRiel
# sqx2t4aJ8Yi1BTpoXqMZPKQNGyC6l9AwInXELfS5O6QJ4dpyteu+SSDlTra8wNlO
# uSc73SHM1Ag3huFShTLq3wpe0JAZoOvhvhdJTYemCSHYS6eF1a0Sape7BeIqlxWn
# M+ZMPhXvUgvr0Ur5zYM6xg3d80fqDyacKgJkPW/OUrA0cBbsLOcHmZ3N6zEqPnGD
# 7VCQgb6S037aTJ8rzRVy3nD5NJpNK9baJ5VqZtON
# SIG # End signature block


