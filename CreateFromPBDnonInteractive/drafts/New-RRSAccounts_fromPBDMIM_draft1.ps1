<#

Создавать учетки всем в домене СЕ, кроме : «директор», «начальник», «руководитель» сотрудникам у кого в должности есть такое слово создавать в доменне GD/

Давай сначала сделаем по Москве.


Доступ к сетевой папке где файлики с данными будут, тем же плюс группа CM_MSK_RRS_RemoteControl_ONLY_POS

Ящик отдела кадров для отправки пароля hr.rrs@rt.ru
#>

$Account_owner= $(whoami)
$ErrorActionPreference = "Continue"
$date = (get-date).tostring("yyyy-MM-dd")
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
# Функция транслитерации
function global:TranslitToLAT
{
param([string]$inString)
 
$Translit_To_LAT = @{
[char]'а' = "a"
[char]'А' = "A"
[char]'б' = "b"
[char]'Б' = "B"
[char]'в' = "v"
[char]'В' = "V"
[char]'г' = "g"
[char]'Г' = "G"
[char]'д' = "d"
[char]'Д' = "D"
[char]'е' = "e"
[char]'Е' = "E"
[char]'ё' = "e"
[char]'Ё' = "E"
[char]'ж' = "zh"
[char]'Ж' = "Zh"
[char]'з' = "z"
[char]'З' = "Z"
[char]'и' = "i"
[char]'И' = "I"
[char]'й' = "y"
[char]'Й' = "Y"
[char]'к' = "k"
[char]'К' = "K"
[char]'л' = "l"
[char]'Л' = "L"
[char]'м' = "m"
[char]'М' = "M"
[char]'н' = "n"
[char]'Н' = "N"
[char]'о' = "o"
[char]'О' = "O"
[char]'п' = "p"
[char]'П' = "P"
[char]'р' = "r"
[char]'Р' = "R"
[char]'с' = "s"
[char]'С' = "S"
[char]'т' = "t"
[char]'Т' = "T"
[char]'у' = "u"
[char]'У' = "U"
[char]'ф' = "f"
[char]'Ф' = "F"
[char]'х' = "kh"
[char]'Х' = "Kh"
[char]'ц' = "ts"
[char]'Ц' = "Ts"
[char]'ч' = "ch"
[char]'Ч' = "Ch"
[char]'ш' = "sh"
[char]'Ш' = "Sh"
[char]'щ' = "sch"
[char]'Щ' = "Sch"
[char]'ъ' = "787" # "``"
[char]'Ъ' = "787" # "``"
[char]'ы' = "y" # "y`"
[char]'Ы' = "Y" # "Y`"
[char]'ь' = "787" # "`"
[char]'Ь' = "787" # "`"
[char]'э' = "e" # "e`"
[char]'Э' = "E" # "E`"
[char]'ю' = "yu"
[char]'Ю' = "Yu"
[char]'я' = "ya"
[char]'Я' = "Ya"
}
 
$outChars=""
 
foreach ($c in $inChars = $inString.ToCharArray())
{
if ($Translit_To_LAT[$c] -cne $Null )
{
$outChars += $Translit_To_LAT[$c] -replace "787",""
}
else
{
$outChars += $c
}
 
}
 
Write-Output $outChars
 
}

#----------------------------------------------------------------------
#get data from DB
[string] $Server= "10.31.3.3"
[string] $Database = "DataExchangeDB"
[string] $SqlQuery= $("SELECT * FROM [DataExchangeDB].[MIMS].[Persons_FULL_and_uvol]  where `
([company] like '%Филиал `"Центр`" ООО `"Ростелеком - Розничные системы`"%' or [company] like '%Головной офис ООО `"Ростелеком - Розничные системы`"%')`
and ([extensionAttribute9] like '%ТД: основное место работы%' or [extensionAttribute9] like '%ТД: внешнее совместительство%') and [require_login] like '%Y%' `
and [ASSIGNMENT_START_DATE] >= DATEADD(DAY,-5,CURRENT_TIMESTAMP)`
and [extensionAttribute11] like '%москва%'")
#'Головной офис ООО "Ростелеком - Розничные системы"'
#'Филиал "Центр" ООО "Ростелеком - Розничные системы"'
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
 
#$DataSet.Tables[0] | out-file "C:\temp2\RRS.csv" -force
$PayloadData = $DataSet.Tables[0]

# EO get data from DB
#---------------------------------------------------------------------
# default Variable Set
$ConnectionExchange_CE = 'http://sce09ex02.ce.rt.ru/PowerShell'
$GC_CE = 'scedr08dc001.ce.rt.ru:3268'
$DC_CE = 'scedr08dc001.ce.rt.ru'
$dbname_CE= 'ce-min-001','ce-min-002','ce-min-003','ce-min-004','ce-min-005','ce-min-006','ce-min-007' |Get-Random
$OU_CE = 'OU=Users,OU=RRS,DC=ce,DC=RT,DC=RU'
$DestPathLogsRRS = '\\Mt.rt.ru\public\IT\New accounts\Logs\RRS'
$tempfolder = 'C:\temp'
$ErrorFolder = 'C:\WorkSet\Error'


$ConnectionExchange_GD = 'http://SGD02EX010.gd.rt.ru/PowerShell'
$GC_GD = 'sgd02dc001.gd.rt.ru:3268'
$DC_GD = 'sgd02dc001.gd.rt.ru'
$dbname_GD= 'GD02 MBStore02 SGD02EXN02' |Get-Random
$OU_GD = 'OU=Users,OU=MSK,OU=RRS,OU=USERS&PC,OU=GD,DC=GD,DC=RT,DC=RU'
#----------------------------------------------------------------------
#work set
$ExchangeSessionlocal_CE = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionExchange_CE
Import-PSSession $ExchangeSessionlocal_CE -AllowClobber

#$ExchangeSessionlocal_GD = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionExchange_GD
#Import-PSSession $ExchangeSessionlocal_GD -AllowClobber

foreach ($EmployeerRRS in $PayloadData)
    {        $ID = $EmployeerRRS.EmployeeID
       
            
            $Exist_AD_Account = get-aduser -Properties EmployeeID -filter {EmployeeID -eq $ID} -Server $GC_CE 
                IF ($Exist_AD_Account) 
                    {
                    $exist = "User $($Exist_AD_Account.name) with EmployeeID $ID exist in forest RT.RU. Check time is $(get-date)" 
                    $exist|out-file "$tempfolder\Exist_RRS_Users_$date.csv" -Append utf8
                    }
                Else
                    {
                     #create set of attrubutes
                     $Name = $EmployeerRRS.CN
                     $DisplayName = $EmployeerRRS.CN
                     $GivenName = ($EmployeerRRS.CN -split "\s")[1]
                     $Surname =  ($EmployeerRRS.CN -split "\s")[0]
                     $initials  = (($EmployeerRRS.CN -split "\s")[2])[0]
                     $fullinitials = ($EmployeerRRS.CN -split "\s")[2]
                     $Enabled = $true
                     $ConvertGivenName = TranslitToLAT $GivenName
                     $ConvertSurName = TranslitToLAT $Surname
                     $Convertfullinitials = TranslitToLAT $fullinitials
                     $Userpass = New-SWRandomPassword -Count 1 -PasswordLength 10
                     $Hired_date = ($EmployeerRRS.ASSIGNMENT_START_DATE).ToString("yyyy-MM-dd")
                     $Chief = $EmployeerRRS.manager
                     $Address = $EmployeerRRS.extensionAttribute11
                     $MRF = $EmployeerRRS.Division
                     $EmployeeType =$EmployeerRRS.employeeType
                     $EmployeeNumber = $EmployeerRRS.EmployeeNumber
                     $Title = $EmployeerRRS.title
                     


                     
                     
                $k = 0;$n=0;
                #если SAM сразу больше 20 символов применяем схему "первая буква имени.первая буква отчества.фамилия"
                #если все  равно больше - обрезаем до 20 символов
                if (("$ConvertGivenName"+"."+"$ConvertSurName").Length -gt 20) 
                    {
                    $SAMAcc = $ConvertGivenName[0] + "." + ($Convertfullinitials[0..$k] -join "") + "." + "$ConvertSurName";
                    $SAMAcc = $SAMAcc.Substring(0,[System.Math]::Min(20,$SAMAcc.Length));
                    $UPN = $SAMAcc+"@rt.ru";
                    }    
                # в противном случае применяем схему "имя.отчество"
                else 
                    {
                    $SAMAcc = ("$ConvertGivenName"+"."+"$ConvertSurName")
                    $SAMAcc = $SAMAcc.Substring(0,[System.Math]::Min(20,$SAMAcc.Length));
                    $UPN = $SAMAcc+"@rt.ru";
                    }     
                #проверяем уникальность SamAccountName     
                     while (get-aduser -Properties userprincipalname -Filter {SamAccountName -eq $SAMAcc} -Server $GC)
                        
                             {
                             
                             write-host "$SAMAcc exist" -ForegroundColor Yellow
                                                         
                              $SAMAcc = $ConvertGivenName[0] + "." + ($Convertfullinitials[0..$n] -join "") + "." + "$ConvertSurName";
                              $SAMAcc = $SAMAcc.substring(0, [System.Math]::Min(20,$SAMAcc.Length));
                              $UPN = $SAMAcc+"@rt.ru";
                              $n++
                                
                              }#EOF  While

                              #------------------------------------------------------------------------------------
                              #Create Account
                              
                              IF (($Title -match "директор") -or ($Title -match "начальник") -or ($Title -match "руководитель")) {
                                
                                    $attr_newaduser = @{
                                    'Name'= $Name
                                    'SamAccountName' = $SAMAcc
                                    'UserPrincipalName' = $UPN
                                    'DisplayName' = $Name
                                    'GivenName' = $GivenName
                                    'Surname'  = $SurName
                                    'initials' = $initials
                                    'AccountPassword' = (ConvertTo-SecureString -AsPlainText $Userpass -Force)
                                #'AccountPassword' = (ConvertTo-SecureString -AsPlainText "Qwerty1!" -Force)
                                    'Enabled' = $true
                                    'Path' = $OU_GD
                                    'Employeeid' = $ID
                                    }#EO @
                                


                                
                                try {
                                    New-ADUser @attr_newaduser -Server $DC_GD;Start-Sleep -Seconds 7
                                    }
                                catch
                                    {
                                    "Error caught $($Error[0])" |out-file $ErrorFolder\NotCreateAccount-$SAMAcc-$date.txt -Append
                                   
                                    Set-ADUser -identity "CN=$Name,$OU_GD" -Replace @{EmployeeID=$ID} -Server $DC_GD;
                                    Set-ADUser -identity $SAMAcc -Replace @{EmployeeType=$EmployeeType;EmployeeNumber=$EmployeeNumber} -Server $DC_GD;
                                    Set-ADUser -identity "CN=$Name,$OU_GD" -Replace @{extensionAttribute7="Write EmployeeID with new script for future Employeers"} -Server $DC_GD;
                                    $set = "User $Name already exist in OU=RRS. Set EmployeeID = $ID for next operations"
                                    $set| out-file "$tempfolder\set $name $date.csv" -Append utf8
                                    }#EO catch
                                Set-ADUser -identity $SAMAcc -Add @{extensionAttribute8="New Script for future Employeers";EmployeeType=$EmployeeType;EmployeeNumber=$EmployeeNumber;extensionAttribute11=$Address} -Server $DC_GD;
                                #Enable mailbox
                                try {    
                                    Enable-Mailbox -Identity $SAMAcc -Database $dbname_GD -Alias $SAMAcc -DomainController $DC_GD -Force 
                                    }
                                catch {
                                    "Error caught $($Error[0])" |out-file $ErrorFolder\NotCreateAccount-$SAMAcc-$date.txt -Append
                                    }

                                }#EO IF
                               
                               Else {
                                 $attr_newaduser = @{
                                    'Name'= $Name
                                    'SamAccountName' = $SAMAcc
                                    'UserPrincipalName' = $UPN
                                    'DisplayName' = $Name
                                    'GivenName' = $GivenName
                                    'Surname'  = $SurName
                                    'initials' = $initials
                                    'AccountPassword' = (ConvertTo-SecureString -AsPlainText $Userpass -Force)
                                #'AccountPassword' = (ConvertTo-SecureString -AsPlainText "Qwerty1!" -Force)
                                    'Enabled' = $true
                                    'Path' = $OU_CE
                                    'Employeeid' = $ID
                                    }#EO @
                                


                                
                                try {
                                    New-ADUser @attr_newaduser -Server $DC_CE;Start-Sleep -Seconds 7
                                    }
                                catch
                                    {
                                    "Error caught $($Error[0])" |out-file $ErrorFolder\NotCreateAccount-$SAMAcc-$date.txt -Append
                                   
                                    Set-ADUser -identity "CN=$Name,$OU_CE" -Replace @{EmployeeID=$ID} -Server $DC_CE;
                                    Set-ADUser -identity $SAMAcc -Replace @{EmployeeType=$EmployeeType;EmployeeNumber=$EmployeeNumber} -Server $DC_CE;
                                    Set-ADUser -identity "CN=$Name,$OU_CE" -Replace @{extensionAttribute7="Write EmployeeID with new script for future Employeers"} -Server $DC_CE;
                                    $set = "User $Name already exist in OU=RRS. Set EmployeeID = $ID for next operations"
                                    $set| out-file "$tempfolder\set $name $date.csv" -Append utf8
                                    }#EO catch
                                Set-ADUser -identity $SAMAcc -Add @{extensionAttribute8="New Script for future Employeers";EmployeeType=$EmployeeType;EmployeeNumber=$EmployeeNumber;extensionAttribute11=$Address} -Server $DC_CE;
                                #Enable mailbox
                                try {    
                                    Enable-Mailbox -Identity $SAMAcc -Database $dbname_CE -Alias $SAMAcc -DomainController $DC_CE -Force 
                                    }
                                catch {
                                    "Error caught $($Error[0])" |out-file $ErrorFolder\NotCreateAccount-$SAMAcc-$date.txt -Append
                                    }
                                }#EO Else


                                # перемещение УЗ в региональное OU (for future projects)
                                try{    
                                    switch -Wildcard ($Address){
                                    "*Москва*" {Write-Host "It's a Moscow Address $($Address)"}
                                    "*Московская*" {Write-Host "It's a Moscow Address $($Address)"}
                                    #"*Костром*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=KO,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\KO'}
                                    #"*Ярослав*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=YR,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\YR'}
                                    #"*Калу*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=KL,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\KL'}
                                    #"*Курск*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=KR,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\KR'}
                                    #"*Иванов*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=IV,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\IV'}
                                    #"*Белгород*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=BL,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\BL'}
                                    #"*Липец*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=LP,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\LP'}
                                    #"*Орел*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=OR,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\OR'}
                                    #"*Рязан*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=RZ,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\RZ'}
                                    #"*Смоленск*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=SM,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\SM'}
                                    #"*Тул*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=TL,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\TL'}
                                    #"*Тамбов*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=TM,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\TM'}
                                    #"*Твер*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=TR,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\TR'}
                                    #"*Владимир*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=VL,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\VL'}
                                    #"*Воронеж*" {$DN=(Get-ADUser $SAMAcc).DistinguishedName;Move-ADObject -Identity $DN -TargetPath 'OU=Users,OU=VR,OU=MRF Center,DC=ce,DC=RT,DC=RU' -Server $DC -Confirm:$false;$DestPathLogsMRFC ='\\Mt.rt.ru\public\IT\New accounts\Logs\MRFC\VR'}
                                    default {write-host "Address $Address not supported"}

                                }#EO switch
                                }#EO Try
                                catch {$Error[0] |out-file $ErrorFolder\NotMoveAccount-$SAMAcc-$date.txt }

                               
                                
                                # формирование  файла с информацией о новом работнике
                                $info = "" |select EmployeeID,ФИО,Логин,E-mail,Пароль,'Дата приема',Руководитель,Адрес
                                $info.EmployeeID = $ID;
                                $info.ФИО = $Name;
                                $info.Логин = $SAMAcc;
                                $info.'E-mail' = $UPN
                                $info.Пароль = $Userpass;
                                $info.'Дата приема' = $Hired_date;
                                $info.Руководитель = $Chief;
                                $info.Адрес = $Address; 
                                $info | out-file "$DestPathLogsRRS\$name $date.txt" utf8 
                                                                
                                
                    }#EO Else

            
            
    } # EO Foreach





Remove-PSSession *