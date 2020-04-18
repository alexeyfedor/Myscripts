
$Account_owner= $(whoami)
$ErrorActionPreference = "Continue"
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

Function Create-ADUser {
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Imya,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Familiya, 
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Otch
    
    )
    begin{
    #$Account_owner = $(whoami)
    $translit_familia = TranslitToLAT $Familiya
    $translit_imya = TranslitToLAT $imya
    $translit_otch = TranslitToLAT $otch
    $Userpass = New-SWRandomPassword -Count 1 -PasswordLength 8
    $OU = Get-ADOrganizationalUnit -Identity "OU=New_Accounts,OU=Users,OU=DR,OU=MRF Center,DC=ce,DC=RT,DC=RU" -Server "scedr07dc002.ce.rt.ru:3268"
    $SD=$txtBoxSD.Text -replace "\s";
       
    }
    process{
        $richtextboxStatus.Text += "Подключаемся к Exchange `n"
        $ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://scedr07cas03.ce.rt.ru/PowerShell
        Import-PSSession $ExchangeSession

     if(("$translit_imya"+"."+"$translit_familia").Length -le 20) {$SAMAcc = "$translit_imya"+"."+"$translit_familia";$UPN = "$translit_imya"+"."+"$translit_familia"+"@rt.ru"}
     elseif(("$translit_imya"+"."+"$translit_familia").Length -gt 20) {$SAMAcc = "$($translit_imya[0])"+"."+"$translit_familia";$UPN = "$translit_imya"+"."+"$translit_familia"+"@rt.ru"}
        #$mailnickname = "$translit_imya"+"."+"$translit_familia"
        $k=1;
        
        while ((get-aduser -Properties userprincipalname -Filter {userprincipalname -eq $UPN} -Server "scedr07dc002.ce.rt.ru:3268") -ne $null)
                {
                $SAMAcc= $($translit_imya[0]) + "." + $translit_otch.Substring(0,$k) + "." + "$translit_familia"
                $UPN = $($translit_imya[0]) + "." + $translit_otch.Substring(0,$k) + "." + "$translit_familia" + "@rt.ru"
                $k++
                } #EOF while
                
        
        
        #while ((get-recipient -identity $($mailnickname)) -ne $null) 
        #      {
        #      $mailnickname = $($translit_imya[0]) + "." + $translit_otch.Substring(0,$k) + "." + "$translit_familia"
        #      $k++
        #      } #EOF while
        #проверка уникальности UPN

                  
        #модуль создания учетки AD
        $richtextboxStatus.Text += "Создаем пользователя $UPN `n"
        #создаем перечень параметров, которые будут использованы для создания УЗ (сплаттинг)
        $attr_newaduser = @{
        'Name'= "$Familiya"+" "+"$Imya"+" "+"$Otch"
        'SamAccountName' = $SAMAcc
        'UserPrincipalName' = $UPN
        'DisplayName' = "$Familiya"+" "+"$Imya"+" "+"$Otch"
        'GivenName' = $Imya
        'Surname'  = $Familiya
        'initials' = $Otch[0]
        'AccountPassword' = (ConvertTo-SecureString -AsPlainText $userpass -Force)
        #'AccountPassword' = (ConvertTo-SecureString -AsPlainText "Qwerty1!" -Force)
        'Enabled' = $true
        'Path' = $OU
        }

        #Проверка членства в группах для создания УЗ в домене ce.rt.ru
        If(([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Domain Admins") `
        -or ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("GCE_MFOCO_AccountOperators")`
        -or ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("GCE_DR_AccountOperators")
        )

            {
                #если УЗ оператора входит в состав группы, создаем УЗ и почтовый ящик
                New-ADUser @attr_newaduser -Server 'scedr07dc002.ce.rt.ru';
                Start-Sleep 5;
                Set-ADUser -identity $SAMAcc -Add @{extensionAttribute13='DR'} -Server 'scedr07dc002.ce.rt.ru';
                #Set-ADUser -identity $SAMAccountNAme -Add @{extensionAttribute14='CE_Exch2010'} -Server 'scedr07dc002.ce.rt.ru';
                Set-ADUser -identity $SAMAcc -Add @{extensionAttribute8="$($SD)"} -Server 'scedr07dc002.ce.rt.ru';
                Set-ADUser -identity $SAMAcc -Add @{extensionAttribute9="$($Account_owner)"} -Server 'scedr07dc002.ce.rt.ru';
                 #модуль создания почтового ящика
                #$dbname= 'cedr_main01_db','cedr_main03_db','cedr_main04','cedr_main02' |Get-Random
                $dbname= 'cedr_main02','cedr_main05' |Get-Random
               $richtextboxStatus.Text += "Добавляем  E-mail пользователя $($SAMAcc+'@rt.ru') `n"
               Enable-Mailbox -Identity $SAMAcc -Alias $SAMAcc -Database $dbname -DomainController 'scedr07dc002.ce.rt.ru'
               $richtextboxStatus.Text += "Пользователь создан в организационном подразделении `n$OU`nЕго данные:`nЛогин:$SAMAcc`nДомен:ce.rt.ru`nПароль:$userpass`nEmail:$($SAMAcc+'@rt.ru')`n`n`n" 
                            
                    
                    $LOGoutput= "Заявка № $SD. Огранизационное подразделение $OU`. Логин: $SAMAcc. Домен:ce.rt.ru .Пароль:$userpass. Email:$($SAMAcc+'@rt.ru').Учетная запись создана оператором $Account_owner";
                    $LOGoutput | out-file "C:\!Scripts\CreateUserCE\Log\$fIO.txt"
                    
                    remove-PSSession *
                    $txtBoxName.Text = $null
                    $txtBoxSD.Text = $null

            }
            Else
            {
                #если УЗ оператора не входит в состав группы
                $richtextboxStatus.Text += "Учетная запись не создана. У Вас нет прав на создание учетных записей.`n";
            }
        
        
               
           
        }
  
       
        end{
        
        }

}

#Generated Form Function
function GenerateForm {
########################################################################
# Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.9.0
# Generated On: 11/10/2015 3:02 PM
# Generated By: a_fedorenko
########################################################################

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
#endregion

#region Generated Form Objects
$form1 = New-Object System.Windows.Forms.Form
$btnCreate = New-Object System.Windows.Forms.Button
$btnClear = New-Object System.Windows.Forms.Button
$btnQuit = New-Object System.Windows.Forms.Button
$Status = New-Object System.Windows.Forms.GroupBox
$richtextboxStatus  = New-Object System.Windows.Forms.RichTextBox
$grpBoxUserInformation = New-Object System.Windows.Forms.GroupBox
$grpBoxSD = New-Object System.Windows.Forms.GroupBox
$txtBoxSD = New-Object System.Windows.Forms.TextBox
$grpBoxName = New-Object System.Windows.Forms.GroupBox
$txtBoxname = New-Object System.Windows.Forms.TextBox
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.
$handler_textBox2_TextChanged= 
{
#TODO: Place custom script here

}

$btnQuit_OnClick= 
{
#TODO: Place custom script here
$form1.Close()
}

    $btnClear_OnClick= 
{
#TODO: Place custom script here
    $txtBoxname.Text = $null
	$txtBoxSD.Text = $null
	 
	 
	# Clear the RichTextBox Status
	$richtextboxStatus.Text = $null
}

$btnCreate_OnClick= 
{
#TODO: Place custom script here

#проверяем и импортируем модуль AD	
if ((Get-Module -ListAvailable | where { $_.Name -eq 'ActiveDirectory'}) -eq $null) {
		$richtextboxStatus.Text += "Вам нужно инсталлировать модуль ActiveDirectory`n"
		$btnCreate.Enabled = $false
		$btnClear.Enabled = $false

	}
 else {
		# Check if the ActiveDirectory module is allready Imported
		If ((Get-Module ActiveDirectory) -eq $null) {
			Import-Module ActiveDirectory -ErrorAction 'SilentlyContinue'
			$richtextboxStatus.Text += "Импортируем модуль ActiveDirectory`n"
		}
		else {
			$richtextboxStatus.Text += "Модуль ActiveDirectory уже импортирован`n" 
		}
	}
# Присваиваем переменной $SD значение из поля Заявка SD
$SD=$txtBoxSD.Text
# Присваиваем переменной $Name значение из поля ФИО
$Name=$txtBoxName.Text;
#Разделяем ФИО на имя фамилию отчество
$DisName=$Name -split " "
#добавляем имя фамилию отчество в отдельную переменную
$Imya=$DisName[1];$Imya = $Imya.substring(0,1).toupper()+$Imya.substring(1).tolower();$Imya=$Imya -replace '\s{1,}',''
$Familiya=$DisName[0];$Familiya = $Familiya.substring(0,1).toupper()+$Familiya.substring(1).tolower();$Familiya=$Familiya -replace '\s{1,}',''
$Otch=$DisName[2];$Otch = $Otch.substring(0,1).toupper()+$Otch.substring(1).tolower();$Otch=$Otch -replace '\s{1,}',''
$FIO="$Familiya"+" "+"$Imya"+" "+"$Otch"
#Проверка есть ли полные тезки
#проверка существующего ФИО
#$Userpass=New-SWRandomPassword -Count 1 -PasswordLength 8
#$OU=Get-ADOrganizationalUnit -Identity "OU=New_Accounts,OU=Users,OU=DR,OU=MRF Center,DC=ce,DC=RT,DC=RU" -Server "scedr07dc001.ce.rt.ru:3268"

try{$existADFIO=Get-ADUser -Properties EmployeeID,enabled -Filter {Name -eq $FIO} -SearchBase "dc=ce,dc=rt,dc=ru" -Server "scedr07dc001.ce.rt.ru:3268"}
#$count=$existADFIO.count
catch{}
    if($existADFIO.DistinguishedName -match "OU=New_Accounts*"){$richtextboxStatus.Text +="Пользователь $($existAdFIO.name) уже существует в $OU и не может быть создан.`n`n`n";
    $txtBoxName.Text = $null;$txtBoxSD.Text = $null;
    }
    elseif (($existADFIO.Enabled -eq $true) -and ($existADFIO.DistinguishedName -notmatch "OU=New_Accounts*")){
    add-Type -AssemblyName System.Windows.Forms
    $OUTPUT= [System.Windows.Forms.MessageBox]::Show("В домене ce.rt.ru уже есть $count УЗ пользователей с инициалами $($existADFIO.name).`nИх EmployeeID = $($existADFIO.employeeid).Продолжаем создавать УЗ?" , "Status" , 4) 
        if ($OUTPUT -eq "YES" ) 
        {
        #создание учетной записи
        Create-ADUser -Imya $Imya -Familiya $Familiya -Otch $Otch} 
        if ($OUTPUT -eq "NO" ) 
        {$richtextboxStatus.Text += "Процесс создания УЗ остановлен. `n";$txtBoxName.Text = $null;$txtBoxSD.Text = $null;}
        }

    else{
    Create-ADUser -Imya $Imya -Familiya $Familiya -Otch $Otch
    
    Write-Output "Пользователь создается в организационном подразделении `n$OU`nЕго данные:`nЛогин:$mailnickname`nДомен:ce.rt.ru`nПароль:$userpass`nEmail:$($mailnickname+'@center.rt.ru')`n`n`n"
     #&2>>c:temp\errors.txt
    }

      
         
        




}


$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$form1.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 472
$System_Drawing_Size.Width = 792
$form1.ClientSize = $System_Drawing_Size
$form1.DataBindings.DefaultDataSourceUpdateMode = 0
$form1.Name = "form1"
$form1.Text = "Создать пользователя в МРФЦ"


$btnCreate.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 543
$System_Drawing_Point.Y = 437
$btnCreate.Location = $System_Drawing_Point
$btnCreate.Name = "btnCreate"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$btnCreate.Size = $System_Drawing_Size
$btnCreate.TabIndex = 4
$btnCreate.Text = "Создать"
$btnCreate.UseVisualStyleBackColor = $True
$btnCreate.add_Click($btnCreate_OnClick)

$form1.Controls.Add($btnCreate)


$btnClear.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 624
$System_Drawing_Point.Y = 437
$btnClear.Location = $System_Drawing_Point
$btnClear.Name = "btnClear"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$btnClear.Size = $System_Drawing_Size
$btnClear.TabIndex = 3
$btnClear.Text = "Очистить"
$btnClear.UseVisualStyleBackColor = $True
$btnClear.add_Click($btnClear_OnClick)

$form1.Controls.Add($btnClear)


$btnQuit.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 705
$System_Drawing_Point.Y = 437
$btnQuit.Location = $System_Drawing_Point
$btnQuit.Name = "btnQuit"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$btnQuit.Size = $System_Drawing_Size
$btnQuit.TabIndex = 2
$btnQuit.Text = "Выход"
$btnQuit.UseVisualStyleBackColor = $True
$btnQuit.add_Click($btnQuit_OnClick)

$form1.Controls.Add($btnQuit)


$Status.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 470
$System_Drawing_Point.Y = 1
$Status.Location = $System_Drawing_Point
$Status.Name = "Status"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 425
$System_Drawing_Size.Width = 310
$Status.Size = $System_Drawing_Size
$Status.TabIndex = 1
$Status.TabStop = $False
$Status.Text = "Статус операции"

$form1.Controls.Add($Status)
$richtextboxStatus.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 6
$System_Drawing_Point.Y = 19
$richtextboxStatus.Location = $System_Drawing_Point
$richtextboxStatus.Name = "richtextboxStatus "
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 400
$System_Drawing_Size.Width = 298
$richtextboxStatus.Size = $System_Drawing_Size
$richtextboxStatus.TabIndex = 0
$richtextboxStatus.Text = ""

$Status.Controls.Add($richtextboxStatus )



$grpBoxUserInformation.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 1
$grpBoxUserInformation.Location = $System_Drawing_Point
$grpBoxUserInformation.Name = "grpBoxUserInformation"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 425
$System_Drawing_Size.Width = 439
$grpBoxUserInformation.Size = $System_Drawing_Size
$grpBoxUserInformation.TabIndex = 0
$grpBoxUserInformation.TabStop = $False
$grpBoxUserInformation.Text = "Информация о пользователе"

$form1.Controls.Add($grpBoxUserInformation)

$grpBoxSD.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 15
$System_Drawing_Point.Y = 118
$grpBoxSD.Location = $System_Drawing_Point
$grpBoxSD.Name = "grpBoxSD"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 53
$System_Drawing_Size.Width = 405
$grpBoxSD.Size = $System_Drawing_Size
$grpBoxSD.TabIndex = 1
$grpBoxSD.TabStop = $False
$grpBoxSD.Text = "Номер заявки"

$grpBoxUserInformation.Controls.Add($grpBoxSD)
$txtBoxSD.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 7
$System_Drawing_Point.Y = 20
$txtBoxSD.Location = $System_Drawing_Point
$txtBoxSD.Name = "txtBoxSD"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 392
$txtBoxSD.Size = $System_Drawing_Size
$txtBoxSD.TabIndex = 0
$txtBoxSD.add_TextChanged($handler_textBox2_TextChanged)

$grpBoxSD.Controls.Add($txtBoxSD)



$grpBoxName.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 15
$System_Drawing_Point.Y = 44
$grpBoxName.Location = $System_Drawing_Point
$grpBoxName.Name = "grpBoxName"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 53
$System_Drawing_Size.Width = 405
$grpBoxName.Size = $System_Drawing_Size
$grpBoxName.TabIndex = 0
$grpBoxName.TabStop = $False
$grpBoxName.Text = "ФИО"

$grpBoxUserInformation.Controls.Add($grpBoxName)
$txtBoxname.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 7
$System_Drawing_Point.Y = 20
$txtBoxname.Location = $System_Drawing_Point
$txtBoxname.Name = "txtBoxname"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 392
$txtBoxname.Size = $System_Drawing_Size
$txtBoxname.TabIndex = 0

$grpBoxName.Controls.Add($txtBoxname)



#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $form1.WindowState
#Init the OnLoad event to correct the initial state of the form
$form1.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form1.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm

# SIG # Begin signature block
# MIIMlQYJKoZIhvcNAQcCoIIMhjCCDIICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1iNH1LIE1+nCKs1t6ju3YCWD
# lfegggoeMIID5jCCAs6gAwIBAgIQUbGzQnDUi1iUINHCVBzmSzANBgkqhkiG9w0B
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
# MIIGMDCCBRigAwIBAgIKKHUPfgAAAAAHqjANBgkqhkiG9w0BAQUFADAyMQswCQYD
# VQQGEwJSVTETMBEGA1UEChMKUm9zdGVsZWNvbTEOMAwGA1UEAxMFSUNBQ0UwHhcN
# MTUwOTIyMTE0MDU5WhcNMTgwOTIxMTE0MDU5WjCBkzESMBAGCgmSJomT8ixkARkW
# AlJVMRIwEAYKCZImiZPyLGQBGRYCUlQxEjAQBgoJkiaJk/IsZAEZFgJjZTETMBEG
# A1UECxMKTVJGIENlbnRlcjELMAkGA1UECxMCRFIxGTAXBgNVBAsMEFNlcnZpY2Vf
# YWNjb3VudHMxGDAWBgNVBAMMD0NFRFJfU2lnbl9BZ2VudDCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAO2z0vtkkl+Da8e61YArtS19EYxf9lndenm78beJ
# UA9qt/1hnFuW92xfhwv13JB/JX3wJVEG6tz6GsgBo6+eyihFbb6wXHKAhv0EhsOF
# dDIS0hGFZYWZkrEKNkkWr4w1VNytFVmURCa85KJ1aS1L8odvT1XRKoin56DsSd5Y
# xXxcy7jaYlkPiqH27qOpRwKXlLSze3JVWtn4D0Uei7U5+6bGMQJ6TZJETzNdS8fp
# CUFiAC0UV8iIxkTIMljIW/9OBbQsoEpMop5fgWIsPULIhw8AhDrAM6sdtDkIxi/d
# rYrQf9Kh9JeDJMAUKPCxlwyDCtXx5PPdkdhbX0l/fbmPeqMCAwEAAaOCAuQwggLg
# MDsGCSsGAQQBgjcVBwQuMCwGJCsGAQQBgjcVCJ76F4X5ynCD6ZcjhdPQDv7PIDCC
# 6KAYhvOnXgIBZAIBBDATBgNVHSUEDDAKBggrBgEFBQcDAzALBgNVHQ8EBAMCB4Aw
# GwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU14dQd0Mp6E3q
# Zol0roks4xLe89QwHwYDVR0jBBgwFoAUFfH06KAFgSaFENuk/9JH1fTZf/8wgewG
# A1UdHwSB5DCB4TCB3qCB26CB2IaBq2xkYXA6Ly8vQ049SUNBQ0UsQ049U0NFRFIw
# N0NBMDAxLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2
# aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPVJULERDPVJVP2NlcnRpZmljYXRlUmV2
# b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2lu
# dIYoaHR0cDovL3BraXBwLmNlLnJ0LnJ1L0NlcnREYXRhL0lDQUNFLmNybDCB/QYI
# KwYBBQUHAQEEgfAwge0wgZ4GCCsGAQUFBzAChoGRbGRhcDovLy9DTj1JQ0FDRSxD
# Tj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049
# Q29uZmlndXJhdGlvbixEQz1SVCxEQz1SVT9jQUNlcnRpZmljYXRlP2Jhc2U/b2Jq
# ZWN0Q2xhc3M9Y2VydGlmaWNhdGlvbkF1dGhvcml0eTBKBggrBgEFBQcwAoY+aHR0
# cDovL3BraXBwLmNlLnJ0LnJ1L0NlcnREYXRhL1NDRURSMDdDQTAwMS5jZS5SVC5S
# VV9JQ0FDRS5jcnQwMwYDVR0RBCwwKqAoBgorBgEEAYI3FAIDoBoMGENFRFJfU2ln
# bl9BZ2VudEBjZS5SVC5SVTANBgkqhkiG9w0BAQUFAAOCAQEAKv11P9tTkjta0oFf
# fIH8Ie269IZxUMe1NCJiS5JKIFSyWsvXc36tgAg9rqi1HHcWODh7+Upaiq1YfQ4q
# FqNt/k1wPqD+8z93xDzbREvLuDlg0FpfYXwEOWJLYmtkz0o4PEv5toMFZCgiz+CW
# 8JZddybLTr08zrj0NbFG+eHSEfeAdu+6+m/DNWgiPrPp0d/aAVm1n4PAlT5eRsqI
# vT/lCngYieDczJfa4w2Nmoh0oJ5wb5bWlkyjr9biAjXujm1xLT+tW+n9aMlIVpr7
# 4D/rxYf39NaWHV2N5ATQVaZSCgVX++us+hcHVrGzoMCkuuD0wtAlaG2jIYcYGDed
# y6FknDGCAeEwggHdAgEBMEAwMjELMAkGA1UEBhMCUlUxEzARBgNVBAoTClJvc3Rl
# bGVjb20xDjAMBgNVBAMTBUlDQUNFAgoodQ9+AAAAAAeqMAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBSQ+25HFstjC8fP6AdqU1G3RFW0BjANBgkqhkiG9w0BAQEFAASCAQBU8jqbaYZ0
# 9gGiozPIWV0+lWM13fNXRO+BSeVsc52WivSiqUWdtvGFGC1cYTtf01MvaOxvQ3K/
# 2Qp4a2mw+nPEeaGFx8SkiDViN78EX8DuUNWXh8is5ZxueG0A3ixamkPuOLlWLpdr
# QSnVMbaojcQ41cygEtKjHk5qP4Yp9elZuVC+gMm1rFwHsciz5KByN6SFY1A0bEbj
# 9YQZTwoGY86Y5UOPZmHNtB+WevPSppSfDLAGZiA0EwyLmtD88QcFXpILJ8hH1Pro
# 0YnIvrBrpCQeYm1dFnPphufq/DP5NBKsgHp6acWnGSGWWag3O5D6iAqCKYKu5qQG
# v7qR0yBrju1m
# SIG # End signature block
