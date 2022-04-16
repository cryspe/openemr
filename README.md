# OpenEMR Vulnerability Discovery

## Description
Electronic Medical Record (EMR) System vulnerabilities provide an easy target for hackers to steal valuable personal data.  With an average cost to a healthcare provider of $9.23 million per hacking incident (Ponemon Institute, 2021)[^Ponemon], EMR vendors need to work with security researchers to review, discover, and patch these vulnerabilities before attackers exploit them.  While the security community has made some efforts to disclose vulnerabilities, these efforts are often sporadic and rely on niche feature sets to be enabled.  Security researchers’ limited time and resources need to be focused on the most used and most likely to be exploited targets in these EMR applications.  This whitepaper utilizes vulnerability exploitation in a popular open-source EMR application to provide specific areas for researchers to focus efforts on securing the applications that protect this valuable data.

## Purpose
These vulnerabilities were discovered while completing the research project related to the Masters in Cyber Security Engineering through the SANS Institute.

## Timeline

### Disclosure
The vulnerabilities were privately disclosed to the application vendor on January 24th, 2022.  An embargo on the public disclosure of the vulnerabilities was requested for 90 days.

### Response
OpenEMR replied on January 26th, 2022 that they received and were working on incorporating safeguards to mitigate the vulnerabilities in the next patch release, 6.0.0 Patch 4.

### Patch
OpenEMR 6.0.0 Patch 4 was released on February 20th, 2022 containing fixes for all reported vulnerabilities.

OpenEMR 6.1.0 was released on March 22nd, 2022 containing fixes for all reported vulnerabilities.

### Report
A research paper outlining a method to prioritize vulnerability hunting was established to assist others in discovering, exploiting and reporting vulnerabilities.

The paper will be linked once available, but the sections are included in the project for review.

1. [Introduction](https://github.com/cryspe/openemr/blob/main/1%20-%20Introduction.md)  
2. [Research Method](https://github.com/cryspe/openemr/blob/main/2%20-%20Research%20Method.md)  
3. [Findings and Discussion](https://github.com/cryspe/openemr/blob/main/3%20-%20Findings%20and%20Discussion.md)  
    1. [Date of Birth Information Leak](https://github.com/cryspe/openemr/blob/main/3.1%20-%20Date%20of%20Birth%20Information%20Leak.md)  
    2. [Unauthorized Patient Insurance Update](https://github.com/cryspe/openemr/blob/main/3.2%20-%20Unauthorized%20Patient%20Insurance%20Update.md)  
    3. [Denial of Service by Self-Registration](https://github.com/cryspe/openemr/blob/main/3.3%20-%20Denial%20of%20Service%20by%20Self-Registration.md)  
    4. [Uncredentialed Patient Portal API Access](https://github.com/cryspe/openemr/blob/main/3.4%20-%20Uncredentialed%20Patient%20Portal%20API%20Access.md)  
    5. [Self-Registration Feature Requirement](https://github.com/cryspe/openemr/blob/main/3.5%20-%20Self-Registration%20Feature%20Requirement.md)  
4. [Recommendations and Implications](https://github.com/cryspe/openemr/blob/main/4%20-%20Recommendations%20and%20Implications.md)  
5. [Conclusion](https://github.com/cryspe/openemr/blob/main/5%20-%20Conclusion.md)  

---------------------
To contact the author please send inquiries to <chris@rabidconsult.com>

[^Ponemon]: Ponemon Institute, LLC (2021).  Cost of a Data Breach Report 2021 (IBM Security Report 2021). Retrieved from https://www.ibm.com/security/data-breach