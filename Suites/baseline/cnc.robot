*** Settings ***
Documentation      System, environment and configuration baseline and verification.

Library	 Collections			
Library	 RequestsLibrary			
Library  SSHLibrary  timeout=60
Library  String
Library  DateTime
#Library  HttpLibrary.HTTP
Library  OperatingSystem
Library  JSONLibrary


Resource 	../../Resources/CW_Keywords.robot
Resource	../../Variables/CW_Environments.robot


Suite Setup				Suite Setup
Suite Teardown         	Suite Teardown

*** Variables ***
${BASE}	${CURDIR}
${ENV}	dcloud-demo
${PASSX}	PASS
${FAILX}	**FAIL

*** Test Cases ***		
		
Logon CNC
	[Documentation]	Initial Authentication for CNC session
	[Tags]  SETUP-TASKS	AUTH
	[setup]    Set Test Variable    ${MSG}    ENVIRONMENT:${ENV}\n   	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}
	#Logon to CNC	${CW_ENDPOINTS["${ENV}"]}
	${data}  set variable  ${CW_ENDPOINTS["${ENV}"]}
	${logon}=  Run Keyword And Return Status  Logon to CNC	${CW_ENDPOINTS["${ENV}"]}
	Run Keyword If  not ${logon}  Fatal Error	Failed to authenticate to ${data} or is not reacheable. Terminating test suite.
		
Get Current Time
	[Documentation]	Get a suite wide date and time to use as a unique identifier
	[Tags]  SETUP-TASKS
	[teardown]    Set Test Message    ${now}	
	Get Current DTTM

Retrieve Platform Summary	
	[Documentation]	Get key information on CNC Platform and hosting
	[Tags]  DATA-COLLECTION	PLATFORM
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-platform

Retrieve Devices	
	[Documentation]	Find key device information
	[Tags]  DATA-COLLECTION	DEVICE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-devices

Retrieve All Service Types	
	[Documentation]	Find all NSO service types (Yang models)
	[Tags]  DATA-COLLECTION	NSO
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-service-types-v2
	
Retrieve All VPN Services	
	[Documentation]	Find all CNC Network Services
	[Tags]  DATA-COLLECTION	SERVICE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-services

Retrieve All VPN Transport	
	[Documentation]	Find all CNC Transport
	[Tags]  DATA-COLLECTION	SERVICE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-transport

Retrieve Application Health	
	[Documentation]	Find Health of CNC applications
	[Tags]  DATA-COLLECTION	APPLICATIONS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-application-health



Retrieve Device Alerts
	[Documentation]	Find all the current /active device alerts
	[Tags]  DATA-COLLECTION
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-device-alerts

Retrieve System Alarms
	[Documentation]	Find all the current /active system alarms
	[Tags]  DATA-COLLECTION
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-system-alarms

Retrieve Providers
	[Documentation]	Find Providers
	[Tags]  DATA-COLLECTION	PROVIDERS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cw-providers

Retrieve Credentials
	[Documentation]	Find credential policies
	[Tags]  DATA-COLLECTION	CREDENTIALS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-credentials
	
Retrieve KPIs
	[Documentation]	Find all the configured KPIs by category
	[Tags]  DATA-COLLECTION	KPIS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-kpis
	
Retrieve CW Versions
	[Documentation]	Find all the Crosswork modules and versions
	[Tags]  DATA-COLLECTION	APPLICATIONS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-application-versions

Retrieve Data Gateway
	[Documentation]	Find the Data Gateway hosts and IP
	[Tags]  DATA-COLLECTION	DATA_GATEWAY
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-data-gw

Retrieve Syslog Destinations
	[Documentation]	Find all the remote syslog destinations
	[Tags]  DATA-COLLECTION	SYSLOG
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-syslog-dest

Retrieve Software Images
	[Documentation]	Find Software Images (SWIM)
	[Tags]  DATA-COLLECTION	SWIM
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-swim-images

Validate Data Gateway
	[Documentation]	Validate the configured DGW is correct as per file spec
	[Tags]  VALIDATE	DATA_GATEWAY
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-dgw2

Validate Platform Summary	
	[Documentation]	Validate key information on CNC Platform and hosting
	[Tags]  VALIDATE	PLATFORM
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-platform

Validate CW Versions
	[Documentation]	Validate the configured CW products are correct as per file spec
	[Tags]  VALIDATE	APPLICATIONS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cw-versions

Validate NSO Service Types
	[Documentation]	Validate the available service models are correct as per file spec
	[Tags]  VALIDATE	NSO
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-service-types	
	
Validate CNC Credentials
	[Documentation]	Validate CNC credentials are correct as per the file spec
	[Tags]  VALIDATE	CREDENTIALS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-credentials
	
Validate CNC Providers
	[Documentation]	Validate CNC Providers are correct as per the file spec
	[Tags]  VALIDATE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-providers	
	
Validate CNC Devices
	[Documentation]	Validate CNC Device info is correct, reachable and in operational OK state (as per spec)
	[Tags]  VALIDATE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-devices

Validate SWIM Images
	[Documentation]	Validate Software Image repository
	[Tags]  VALIDATE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-swim-images

Validate Application Health
	[Documentation]	Ensure all CNC applications are health
	[Tags]  VALIDATE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-application-health
	



