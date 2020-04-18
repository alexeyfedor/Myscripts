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
#$ExchangeSessionlocal_CE = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionExchange_CE
#Import-PSSession $ExchangeSessionlocal_CE -AllowClobber


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
                                   
                                   if (-not ($ExchangeSessionlocal_GD.State -eq 'opened')){$ExchangeSessionlocal_GD = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionExchange_GD
                                    Import-PSSession $ExchangeSessionlocal_GD -AllowClobber}
                                   try {
                                    Enable-Mailbox  -Identity $SAMAcc -Database $dbname_GD -Alias $SAMAcc -DomainController $DC_GD -Force 
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
                                
                                if (-not ($ExchangeSessionlocal_CE.State -eq 'opened')) {$ExchangeSessionlocal_CE = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ConnectionExchange_CE
                                    Import-PSSession $ExchangeSessionlocal_CE -AllowClobber}
                                
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

