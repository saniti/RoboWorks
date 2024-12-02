# RoboWorks
RoboWorks is a Robotframework test suite specifically for testing, validation and testing of Cisco Crosswork Network Controller [CNC](https://www.cisco.com/c/en/us/products/collateral/cloud-systems-management/crosswork-network-automation/solution-overview-c22-739633.html)
## Overview
RoboWorks deviates slightly from standard Robotframework test cases and keyword construction which typically define test cases with a `pass` or `fail` condition by splitting into the test cases into 2 distinct types:
- Discovery
and
- Validation

**Discovery** tests are executed first, and are primarily responsible for collection of key metrics or information from CNC and displaying these as lists in the output report. They will fail if collection fails, but otherwise will present the collected data visually on the report.
This data is stored (for each test case) as a `suite variable`, making the data available during other test cases (`validation` cases).

**Validation** tests are also split into a couple of different types of tests:
* Validation of the associated `suite variable` data against list (or baseline) of expected results. 
* Validation against some basic thresholds for cases such as performance.

This makes it very extensible and easy to write new tests but following the format:
1. Identify the API data you wish to extract from CNC
1. Clone an existing test cases and give it a new name and description
1. Clone an existing 'get-' keyword and modify the API call, BODY and expected result (typically `200`)
1. Identify the data you want to capture
1. Change the name of the `suite variable`. 

Once the above is done, running the script will produce captured data in the test result. You can actually just copy this data and put it into the baseline - which makes it very easy to create and modify a new baseline with a new environment / install.

## Features
### Multiple Environments
There is a single file `CW_Environments.robot` that supports:
- Multiple credentials (in clear text)
- Multiple hosts/environments
- The key name simply maps to a directory location where environment specific baseline content is stored.

Environment File: `Variables/CW_Environments.robot`

***Credential Example***
```json
${admin_default}  Set Variable	{"username":"admin","password":"MyCNCPasswordGoesHere"}
```
     
***Environment Example***
```json
set to dictionary  ${CW_ENDPOINTS}  cnclabdemo  {"host":"cnclabdemo","protocol":"https","port":"30605","auth":${admin_default}}
```
Once a new environment has been created, you can either:
- Change the `cnc.robot` file to point to the new name by changing this parameter:
```html
${ENV}	cnclab
```
- Run the test script passing the appropriate environment variable
```bash
robot -e v ENV:newcncenvironment cnc.robot
```

### Creating Baselines
Baselines can easily be created for a new environment by simply adding the environment (above) and running the test. The process is identical to the above
- Create new credentials and host definition in the `CW_Environments` file
- Execute the test `robot -e ENV:<environment> cnc.robot`

This will `fail` all of the validation tests - but that's ok, because we have now captured all the necessary data to populate our baseline!

Baseline data is stored in files under `Suites\baseline\ENV\<environment>`

Current, the test support validation of the following baseline data sets:
 File               | Description             
--------------------|-------------------------
 cw-apps.txt        | CNC Applications        
 cw-credentials.txt | CNC Credential Policies 
 cw-devices.txt     | CNC Devices             
 cw-images.txt      | CNC Images (SWIM)       
 cw-platform.txt    | CNC Platform            
 cw-providers.txt   | CNC Providers           
 cw-services.txt    | CNC Network Services    
 dgw-hosts.txt      | CNC Data Gateway        
 syslog.txt         | CNC Syslog definitions  

Simply populate the captured data from the `DATA-COLLECTION` steps into the appropriate text file. Next run - this will validate the data and you should see a pass. 
At this stage - you have a baseline. You can manipulate the files as you wish or leave them as a true baseline -  and run the script later and it will fail tests against data that has changed. 
   
## Output Examples
![plot](./img/output1.png)

