
$FormatEnumerationLimit=-1
$date=(get-date).ToString('dd/MM/yyyy')
$DestFolder = "C:\WorkSet"
$DestFolderHTML = "C:\WorkSet\HTML"
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

$Pre = "<b>Учетные данные для нового работника - $date</b>"
#$Post = "Footer after the report"


#----------------------------------------------------------------------
#получаем данные из ПБД
[string] $Server= "10.31.3.3"
[string] $Database = "DataExchangeDB"
[string] $SqlQuery= $("SELECT * FROM [DataExchangeDB].[MIMS].[Persons_FULL_and_uvol]  where [company] like '%МРФ `"Центр`" ПАО `"Ростелеком`"%' and [extensionAttribute9] like '%основное место работы%' and ([require_login] like '%Y%' or [lev_grade] ='2' or [lev_grade] ='3')")
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

$GC = 'scedr07dc001.ce.rt.ru:3268'
$DC = 'scedr07dc001.ce.rt.ru'



#-----------------------------------------------------------------

foreach ($Employeer in $PayloadData)
    {
        $ID = $Employeer.EmployeeID
        IF (($Employeer.Hire_Date).ToString("yyyy-MM-dd") -eq (Get-Date).ToString("yyyy-MM-dd"))
            {
                 
            try {
                $Exist_AD_Account = get-aduser -Properties EmployeeID -filter {EmployeeID -eq $ID} -Server $GC
               
                #create set of attrubutes
                     $Name = $Exist_AD_Account.name
                     $DisplayName = $Exist_AD_Account.name
                     $SAMAcc = $Exist_AD_Account.samaccountname
                     $UPN = $Exist_AD_Account.userprincipalname
                     #$GivenName = ($Employeer.CN -split "\s")[1]
                     #$Surname =  ($Employeer.CN -split "\s")[0]
                     #$initials  = (($Employeer.CN -split "\s")[2])[0]
                     #$fullinitials = ($Employeer.CN -split "\s")[2]
                     #$Enabled = $true
                     #$OU = 'OU=New_Accounts,OU=GD_USERS,OU=USERS&PC,OU=GD,DC=GD,DC=RT,DC=RU' 
                     #$ConvertGivenName = TranslitToLAT $GivenName
                     #$ConvertSurName = TranslitToLAT $Surname
                     #$Convertfullinitials = TranslitToLAT $fullinitials
                     #$Userpass = New-SWRandomPassword -Count 1 -PasswordLength 8
                     $Hired_date = ($Employeer.hire_date).ToString("yyyy-MM-dd")
                     $Hired_date_for_Email = ($Employeer.hire_date).ToString("dd.MM")
                     $Chief = $Employeer.manager
                     $ChiefIO = ([string](($Employeer.Manager -split " ")[1,2]))
                     $MailChief = [string]$Employeer.mail_chif
                     $Address = $Employeer.extensionAttribute11
                     #$MRF = $Employeer.Division
                     $EmployeeType =$Employeer.employeeType
                     $EmployeeNumber = $Employeer.EmployeeNumber
                     
                     

                #$ChiefMail = $Employeer.managerEmail 
                #$Userpass = $Userpass = New-SWRandomPassword -Count 1 -PasswordLength 8
                #$newpwd = (ConvertTo-SecureString -AsPlainText $Userpass -Force)
                #Set-ADAccountPassword $Exist_AD_Account -NewPassword $newpwd -Reset -PassThru
                #Set-ADUser $Exist_AD_Account -ChangePasswordAtLogon $true
                
                $info = "" |select EmployeeID,ФИО,Логин,E-mail,Пароль,'Дата приема',Руководитель,Адрес
                                $info.EmployeeID = $ID;
                                $info.ФИО = $Name;
                                $info.Логин = $SAMAcc;
                                $info.'E-mail' = $UPN
                                $info.Пароль = $Userpass;
                                $info.'Дата приема' = $Hired_date;
                                $info.Руководитель = $Chief;
                                $info.Адрес = $Address; 
                                $info | export-csv -Path "$DestFolder\$name.csv" -Encoding UTF8 -NoTypeInformation

                Import-Csv -Path "$DestFolder\$name.csv" | ConvertTo-Html -Head $Header -PreContent $Pre | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd|Out-File "$DestFolderHTML\$name.htm"
                $content = Get-Content "$DestFolderHTML\$name.htm";
                $recipient = 'fedorenko@center.rt.ru';
                $altrecipients = 'oleg.nikiforov@rt.ru'


                
                $smtpServer = 'sce09ex01','sce09ex02','sce09ex03','sce09ex04','sce09ex05','sce09ex06' |Get-Random
                $smtpFrom = "NewEmployeerScript@rt.ru"
                $messageSubject = "Внимание. Новый работник"
$body=@"
Здравствуйте $ChiefIO, 
К Вам $Hired_date_for_Email выходит новый сотрудник, огромная просьба в первый день работы передать ему логин и пароль для входа в компьютер:

$content
Заранее огромное спасибо!

"@ 


                $body= "<pre>" + $body | Out-String -Width 4096
                    if ($content.Length -le 18) {Write-Host "file is empty"}
                    else {Send-MailMessage -SmtpServer $smtpserver -To $recipient -From $smtpfrom -cc $altrecipients -Encoding "Unicode" -Subject $messageSubject -Body $body  -BodyAsHtml -ErrorAction SilentlyContinue}


            }
            catch
            {
            write-host "User $($Employeer.ID) not found in Active Directory"
            }
         
        }#EO IF
        #Else {write-host "User $($Employeer.CN) starting work not today" -ForegroundColor Yellow}

}#EO Foreach



