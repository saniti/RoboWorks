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
	[Documentation]	Get key information on CNC Platform and hosting as per file spec [cnc-platform.txt]
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

Retrieve NSO Service Types	
	[Documentation]	Retrieve the available NSO service models
	[Tags]  DATA-COLLECTION	NSO
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-service-types
	
Retrieve CNC VPN Services	
	[Documentation]	Find all CNC Network Services
	[Tags]  DATA-COLLECTION	SERVICES
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-services

Retrieve NSO VPN Transport	
	[Documentation]	Find all CNC Transport services from NSO
	[Tags]  DATA-COLLECTION	SERVICES
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-transport

Retrieve CNC Application Health	
	[Documentation]	Find Health of CNC applications
	[Tags]  DATA-COLLECTION	APPLICATIONS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-application-health

Retrieve CNC Device Alerts
	[Documentation]	Find all the current /active device alerts
	[Tags]  DATA-COLLECTION	DEVICE	ALARMS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-device-alerts

Retrieve CNC System Alarms
	[Documentation]	Find all the current /active system alarms
	[Tags]  DATA-COLLECTION	ALARMS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-system-alarms

Retrieve CNC Providers
	[Documentation]	Find Providers
	[Tags]  DATA-COLLECTION	PROVIDERS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-providers

Retrieve CNC Credentials
	[Documentation]	Find credential policies
	[Tags]  DATA-COLLECTION	CREDENTIALS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-cnc-credentials
	
Retrieve CNC KPIs
	[Documentation]	Find all the configured KPIs by category
	[Tags]  DATA-COLLECTION	KPIS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-kpis
	
Retrieve CNC Versions
	[Documentation]	Find all the Crosswork modules and versions
	[Tags]  DATA-COLLECTION	APPLICATIONS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-application-versions

Retrieve CNC Data Gateway
	[Documentation]	Find the Data Gateway hosts and IP
	[Tags]  DATA-COLLECTION	DATA_GATEWAY
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-data-gw

Retrieve CNC Syslog Destinations
	[Documentation]	Find all the remote syslog destinations
	[Tags]  DATA-COLLECTION	SYSLOG
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-syslog-dest

Retrieve CNC Software Images
	[Documentation]	Find Software Images (SWIM)
	[Tags]  DATA-COLLECTION	SWIM
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  get-swim-images

Validate CNC Data Gateway
	[Documentation]	Validate the configured DGW is correct as per file spec [cnc-cdg.txt]
	[Tags]  VALIDATE	DATA_GATEWAY
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-cdg

Validate Platform Summary	
	[Documentation]	Validate key information on CNC Platform and hosting as per file spec [cnc-platform.txt]
	[Tags]  VALIDATE	PLATFORM
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-platform

Validate CNC Versions
	[Documentation]	Validate the configured CNC products are correct as per file spec [cnc-apps.txt]
	[Tags]  VALIDATE	APPLICATIONS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-app-versions

Validate NSO Service Types
	[Documentation]	Validate the available NSO service models are correct as per file spec [cnc-nso-service-types.txt]
	[Tags]  VALIDATE	NSO
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-nso-service-types	
	
Validate CNC Credentials
	[Documentation]	Validate CNC credentials are correct as per the file spec [cnc-credentials.txt]
	[Tags]  VALIDATE	CREDENTIALS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-credentials
	
Validate CNC Providers
	[Documentation]	Validate CNC Providers are correct as per the file spec [cnc-providers.txt]
	[Tags]  VALIDATE	PROVIDERS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-providers	
	
Validate CNC Devices
	[Documentation]	Validate CNC Device info is correct, reachable and in operational OK state as per the file spec [cnc-devices.txt]
	[Tags]  VALIDATE	DEVICE
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-devices

Validate CNC SWIM Images
	[Documentation]	Validate Software Image repository as per the file spec [cnc-images.txt]
	[Tags]  VALIDATE	SWIM
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-swim-images

Validate CNC Application Health
	[Documentation]	Ensure all CNC applications are healthy
	[Tags]  VALIDATE	APPLICATIONS
	[setup]    Set Test Variable    ${MSG}    ${EMPTY}    	
	[teardown]    Set Test Message    ${MSG}\n${TEST MESSAGE}    
	${RESP}  validate-cnc-application-health
	



