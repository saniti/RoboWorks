*** Keywords ***

Get Current DTTM
	log  LOGLEVEL:${LOG LEVEL}	# Print the currently loglevel
	${now}  get current date  result_format=%Y%m%d-%H%M%S
	set suite variable  ${now}
	log to console  \nCurrent Time: ${now}
    
    
Get NOW time
	${mynow}  get current date  result_format=%Y%m%d-%H%M%S
    RETURN  ${mynow}  

	
valid-groups

    ${startTime}  Run Keyword  Get NOW time  

    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
	
    ${myurl}  Set Variable   /groups/list
    
    ${response}   GET On Session  logon  ${myurl}  expected_status=200

    @{resp}    evaluate  json.loads($response.text)    json

	${GROUPS_LOADED}  Load Data from File  RELEASES${/}${IAP_VER}${/}valid_groups.txt
	${GROUPS_LOADED}  evaluate  json.loads($GROUPS_LOADED)    json

	@{GROUPS_RUNNING_LIST}=    Create List
	@{GROUPS_LOADED_LIST}=    Create List	
	
	FOR  ${item}  IN  @{GROUPS_LOADED}
		Append To List	${GROUPS_LOADED_LIST}	${item}[name]:${item}[provenance]:${item}[_id]
	END

	Log list	${GROUPS_RUNNING_LIST}

	@{GROUPS_RUNNING}=    Create List
	@{FAIL}=    Create List	
	@{PASS}=    Create List		
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	
	
	
	FOR  ${item}  IN  @{resp}
		Log  ${item}[name]
		Append To List  ${GROUPS_RUNNING_LIST}  ${item}[name]:${item}[provenance]:${item}[_id]
	END

	Log List  ${GROUPS_RUNNING_LIST}
	Log List  ${GROUPS_LOADED_LIST}
	
	FOR  ${item}  IN  @{GROUPS_LOADED_LIST}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${GROUPS_RUNNING_LIST}  ${item}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: ${item}	
		Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:Group:provenance Not found or not matched.
	END	

	FOR  ${item}  IN  @{GROUPS_RUNNING_LIST}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${GROUPS_LOADED_LIST}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END	

	${FAIL_LENGTH}=  Get Length  ${FAIL}
	${PASS_LENGTH}=  Get Length  ${PASS}	
	${TOTAL_LENGTH}  Evaluate  ${FAIL_LENGTH} + ${PASS_LENGTH}
	
	Log List  ${PASS}
	Log List  ${FAIL}
	Log List  ${FAIL-REV}	
	
	Run Keyword If  ${FAIL_LENGTH} > 0  
	...  fail  	${FAIL_LENGTH} / ${TOTAL_LENGTH} groups were not matched in the running system.
	
	${length}=  Get Length  ${FAIL-REV}
	
	Run Keyword If  ${length} > 0
	...  Run Keyword  Set Test Variable    ${MSG}     ${MSG}\nWARN: There are groups in the system that are not validated against (orphaned)

valid-services
    [Tags]  IAPSERVICES
 	
    ${myurl}  Set Variable   /health/modules
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${response}   GET On Session  logon  ${myurl}  expected_status=200

    @{MY_DATA_TABLE_VALUES}    evaluate  json.loads($response.text)    json

	${servicesVALID}  Load Data from File  RELEASES${/}${IAP_VER}${/}valid_services.txt
	@{servicesVALID}=    Split to lines  ${servicesVALID}	
	
	log  ${MY_DATA_TABLE_VALUES} 
	
	@{list}=    Create List
	@{FAIL}=    Create List	
	@{PASS}=    Create List		
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	
	
	
	FOR  ${item}  IN  @{MY_DATA_TABLE_VALUES}
		Log  ${item}[id]
		Append To List  ${list}  ${item}[id]:${item}[state]
	END

	Log List  ${list}
	Log List  ${servicesVALID}
	
	FOR  ${item}  IN  @{servicesVALID}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${list}  ${item}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: ${item}	
		Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:Service:version Not found or not matched.
	END	

	FOR  ${item}  IN  @{list}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${servicesVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END	

	# Environment specific list of apps
	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${CURDIR}${/}ENV${/}${ENV}${/}valid_services.txt

	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${list}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
		END

		FOR  ${item}  IN  @{list}
			# Negative		
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
			IF  "${RESP}[0]" == "FAIL"	
				Set Test Variable    ${MSG}    ${MSG}\nWARN: [${ENV}]:${item} Not in valid list.
				Append To List  ${${RESP}[0]-REV}  ${RESP}[0]: [${ENV}]:${item}
			END
		END	
	
	END


	${FAIL_LENGTH}=  Get Length  ${FAIL}
	${PASS_LENGTH}=  Get Length  ${PASS}	
	${TOTAL_LENGTH}  Evaluate  ${FAIL_LENGTH} + ${PASS_LENGTH}
	
	Log List  ${PASS}
	Log List  ${FAIL}
	Log List  ${FAIL-REV}	
	
	Run Keyword If  ${FAIL_LENGTH} > 0  
	...  fail  	${FAIL_LENGTH} / ${TOTAL_LENGTH} services were not present in the running system.
	
	${length}=  Get Length  ${FAIL-REV}
	
	Run Keyword If  ${length} > 0
	...  Run Keyword  Set Test Variable    ${MSG}     ${MSG}\nWARN: There are services running that are not in the valid list

get-cnc-platform

    ${myurl}  Set Variable   /crosswork/platform/v1/node-manager/clusters
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CW_PLATFORM}=    Create List	
	
	@{FIELDS}=	Create List	SchemaVersion	Cw_VM_Image		ClusterIPStack	ManagementVIP	ManagementIPNetmask	ManagementIPGateway	DataVIP	DataIPNetmask	DataIPGateway	DomainName	NTP	DNS	RamDiskSize	ThinProvisioned	Timezone
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Platform Specs--\n
	
	#@{data}    Get Value From Json    ${json_response['CwClusterAndActions']}    $..CwCluster
	
	FOR  ${item}  IN  @{FIELDS}
		${search}	Set Variable 	$..${item}
		${data}	Get Value From Json    ${json_response['CwClusterAndActions']}    ${search}

		Set Test Variable    ${MSG}    ${MSG}${item}:${data}\n
		Append To List  ${CW_PLATFORM}	${item}:${data}
		
	END 
	
	#FOR  ${item}  IN  @{FIELDS}
	#	Log	@{data_json[${item}]}
	#	Append To List  ${CW_PLATFORM}	${data_json[${item}]}		
		
		#Version:${item['SchemaVersion']},Image:${item['Cw_VM_Image']},IPType:${item['ClusterIPStack']},MgmtVIP:${item['ManagementVIP']},MgmtMASK: ${item['ManagementIPNetmask']},MgmtGW:${item['ManagementIPGateway']},Domain:${item['DomainName']},NTP:${item['NTP']},DNS:${item['DNS']},RAMDISK:${item['RamDiskSize']},ThinProvisioned:${item['ThinProvisioned']},Timezone:${item['Timezone']}
		
		#Set Test Variable    ${MSG}    ${MSG}Version: ${item['SchemaVersion']}\nImage: ${item['Cw_VM_Image']}\nIPType: ${item['ClusterIPStack']}\nMgmtVIP: ${item['ManagementVIP']}\nMgmtMASK: ${item['ManagementIPNetmask']}\nMgmtGW: ${item['ManagementIPGateway']}\nDomain: ${item['DomainName']}\nNTP: ${item['NTP']}\nDNS: ${item['DNS']}\nRAMDISK: ${item['RamDiskSize']}\nThinProvisioned: ${item['ThinProvisioned']}\nTimezone: ${item['Timezone']}
			
	#END	

	Set Suite Variable  ${CW_PLATFORM}	
}	

validate-cnc-platform

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cw-platform.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CW_PLATFORM}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  ${CW_PLATFORM}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
			
		END
	END		

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

get-service-types

	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}

	
    ${description}  set variable    ${TEST NAME}
	@{CW_SERVICE_TYPES}=    Create List	
    ${myurl}  Set Variable   /crosswork/nbi/cat-inventory/v1/restconf/operations/cat-inventory-rpc:get-available-service-types

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--NSO Services--
	
	FOR  ${item}  IN  @{json_response['cat-inventory-rpc:output']['get-available-service-types-response']['service-type-info']}
		Set Test Variable    ${MSG}    ${MSG}\n${item['service-type-label']}:${item['service-type']}	
		Append To List  ${CW_SERVICE_TYPES}	${item['service-type-label']}:${item['service-type']}	
	END	

	Set Suite Variable  ${CW_SERVICE_TYPES}	

get-service-types-v2

	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CW_SERVICE_TYPES}=    Create List	
    ${myurl}  Set Variable   /crosswork/cnc/api/v1/serviceTypes
	${payload}	Set Variable	{"transport":true}	

	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--NSO Services--
	
	FOR  ${item}  IN  @{json_response['serviceTypes']}
		Set Test Variable    ${MSG}    ${MSG}\n${item['serviceLayer']}:${item['serviceType']}	
		Append To List  ${CW_SERVICE_TYPES}	${item['serviceLayer']}:${item['serviceType']}	
	END	
	
	Set Suite Variable  ${CW_SERVICE_TYPES}	

get-cnc-services

	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CW_SERVICES}=    Create List	
    ${myurl}  Set Variable   /crosswork/cnc/api/v1/services
	${payload}	Set Variable	{"sortAscending":true,"sortColumn":"serviceName","startRow":0,"endRow":1000,"transport":false,"viewByType":["VPN"],"filterCriteria":{"conditionList":[]}}

	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--VPN Services--
	
	FOR  ${item}  IN  @{json_response['elements']}
		Set Test Variable    ${MSG}    ${MSG}\n${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}	
		Append To List  ${CW_SERVICES}	${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}		
	END	
	
	Set Suite Variable  ${CW_SERVICES}

get-cnc-transport

	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CW_TRANSPORT}=    Create List	
    ${myurl}  Set Variable   /crosswork/cnc/api/v1/services
	
	${payload}	Set Variable	{"sortAscending":true,"sortColumn":"serviceName","startRow":0,"endRow":1000,"transport":false,"viewByType":["TRANSPORT"],"filterCriteria":{"conditionList":[]}}
	
	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--Transport--
	
	FOR  ${item}  IN  @{json_response['elements']}
		Set Test Variable    ${MSG}    ${MSG}\n${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}	
		Append To List  ${CW_TRANSPORT}	${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}	
	END	
	
	Set Suite Variable  ${CW_TRANSPORT}	

get-syslog-dest
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CW_SYSLOG_DEST}=    Create List


    ${myurl}  Set Variable   /crosswork/alarms/v1/syslog-dest/query
	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	
	FOR  ${item}  IN  @{json_response['data']}
		Set Test Variable    ${MSG}    ${MSG}\n${item['host']}:${item['port']}:${item['criteria']}
		Append To List  ${CW_SYSLOG_DEST}	${item['host']}:${item['port']}:${item['criteria']}	
	END	

	Set Suite Variable  ${CW_SYSLOG_DEST}	


validate-syslog-dest

    ${description}  set variable    ${TEST NAME}

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}syslog.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			log 	comparing ${item} against ${CW_SYSLOG_DEST}
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CW_SYSLOG_DEST}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:Syslog entry found in validation list file, but not in system
			Set Tags	${RESP}[0]
		END
	ELSE
		fail 	${FAILX} file [${BASE}${/}ENV${/}${ENV}${/}syslog.txt] does not exist or invalid
	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

get-data-gw

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{DATA_GW}=    Create List	
    ${myurl}  Set Variable   /crosswork/dg-manager/v1/dg/query

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	log	${json_response}
	Set Test Variable    ${MSG}	--Data Gateways--   
	FOR  ${item}  IN  @{json_response['data']}
		log	${item}
		
		${ip}    Get Value From Json    ${item}    $..configData.interfaces[?(@.name=='eth0')].ipAddr..inetAddr
		
		Set Test Variable    ${MSG}    ${MSG}\n${item['name']}:${ip}[0]	
		Append To List  ${DATA_GW}	${item['name']}:${ip}[0]		
	END	

	Set Suite Variable  ${DATA_GW}	

validate-dgw2

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}dgw-hosts.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${DATA_GW}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

get-swim-images

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CW_SWIM_IMAGES}=    Create List	
    ${myurl}  Set Variable   /crosswork/rs/json/SwimRepositoryRestService/getImagesForRepository/

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=206	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	log	${json_response}
	Set Test Variable    ${MSG}    --Images--
	FOR  ${item}  IN  @{json_response['softwareImageListDTO']['items']}
		log	${item}
		
		Set Test Variable    ${MSG}    ${MSG}\n${item['name']}:${item['version']}:${item['family']}:${item['vendor']}	
		Append To List  ${CW_SWIM_IMAGES}	${item['name']}:${item['version']}:${item['family']}:${item['vendor']}		
	END	

	Set Suite Variable  ${CW_SWIM_IMAGES}	

validate-swim-images

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cw-images.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CW_SWIM_IMAGES}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  ${CW_SWIM_IMAGES}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END		

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

get-cnc-devices

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_DEVICES}=    Create List	
    ${myurl}  Set Variable   /crosswork/inventory/v1/nodes/query

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	log	${json_response}
	Set Test Variable    ${MSG}    --Devices--	
	FOR  ${item}  IN  @{json_response['data']}
		log	${item}
		
		#${ip}    Get Value From Json    ${item}    $..configData.interfaces[?(@.name=='eth0')].ipAddr..inetAddr
		
		#Set Test Variable    ${MSG}    ${MSG}\n${item['name']}:${ip}[0]	
		Set Test Variable    ${MSG}    ${MSG}\n${item['host_name']}|${item['reachability_state']}:${item['operational_state']}:${item['profile']}:${item['node_ip']}:${item['product_info']['software_type']}:${item['product_info']['software_version']}
		Append To List  ${CNC_DEVICES}	${item['host_name']}|${item['reachability_state']}:${item['operational_state']}:${item['profile']}:${item['node_ip']}:${item['product_info']['software_type']}:${item['product_info']['software_version']}
	END	

	Set Suite Variable  ${CNC_DEVICES}	

validate-cnc-devices

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cw-devices.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_DEVICES}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  ${CNC_DEVICES}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
			
		END
	END		

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

validate-service-types

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cw-services.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CW_SERVICE_TYPES}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}


get-device-alerts

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	
    ${myurl}  Set Variable   /crosswork/hi/v1/alerts/device/devices
	${payload}	Set Variable	{"time_ago":"0m","offset":"0","time_interval":"1h","levels":["CRITICAL","MAJOR","WARNING","MINOR","INFO"],"limit":"100","top_devices":true}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${alerts}    evaluate  json.loads($response.text)    json
	
	#IF	${${alerts['device_alerts']['total_alerts']}} > ${0}
	
		FOR  ${item}  IN  @{alerts['device_alerts']}
			Log	${item['device_id']}
			Set Test Variable    ${MSG}    ${MSG}\nAlert: ${item['device_id']}:${item['impact_score']}		
		END	
		FOR  ${item}  IN  @{alerts['kpi_alerts']}
			Log	${item['device_id']}
			Set Test Variable    ${MSG}    ${MSG}\nAlert: ${item['device_id']}:${item['impact_score']}		
		END		
	
get-cnc-credentials

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CW_CREDENTIALS}=    Create List	
	
    ${myurl}  Set Variable   /crosswork/inventory/v1/credentials/query
	${payload}	Set Variable	{"limit":100,"next_from":"0","filter":{}}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${credentials}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}    --Credentials--
	
	FOR  ${item}  IN  @{credentials['data']}
		Log	${item}
		Append To List  ${CW_CREDENTIALS}	${item['profile']}
		
		FOR  ${user}  IN  @{item['user_pass']}
			Set Test Variable    ${MSG}    ${MSG}\n${item['profile']}|${user['user_name']}:${user['type']}
			Append To List  ${CW_CREDENTIALS}	${item['profile']}|${user['user_name']}:${user['type']}
		END
		
		#Set Test Variable    ${MSG}    ${MSG}\n${item['profile']}:${item['user_pass']}:${item['type']}			

	END	
	Set Suite Variable  ${CW_CREDENTIALS}

get-cw-providers

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CW_PROVIDERS}=    Create List	
	
    ${myurl}  Set Variable   /crosswork/inventory/v1/providers/query
	${payload}	Set Variable	{"limit":100,"next_from":"0","filter":{}}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${providers}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--Providers--
	FOR  ${item}  IN  @{providers['data']}
		Log	${item}

		
		FOR  ${connectivity}  IN  ${item['connectivity_info']}

		#Set Test Variable    ${MSG}    ${MSG}\n${item['name']}|${item['reachability_state']}
			Set Test Variable    ${MSG}    ${MSG}\n${item['name']}|${item['reachability_state']}:${connectivity}
			Append To List  ${CW_PROVIDERS}	${item['name']}|${item['reachability_state']}:${connectivity}		

		END

	END	
	
	Set Suite Variable  ${CW_PROVIDERS}	

get-system-alarms

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	
    ${myurl}  Set Variable   /crosswork/alarms/v1/query
	${payload}	Set Variable	{"openAlarmsOnly":true,"criteria":"select * from alarm limit 100 page 0 where alarmCategory=1 "}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${alarms}    evaluate  json.loads($response.text)    json
	
	#IF	${${alerts['device_alerts']['total_alerts']}} > ${0}
	
	FOR  ${item}  IN  @{alarms['alarms']}
		Log	${item}
		IF	"${item['State']}" <> "Info"
			Set Test Variable    ${MSG}    ${MSG}\nAlarm: ${item['State']}:${item['object_description']}${item['Description']}		
		END
	END	

get-device-alarms

    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	set to dictionary  ${headers}  Range=items=0-99
	
    ${description}  set variable    ${TEST NAME}
	@{CW_DEVICE_ALARMS}=    Create List	
	
    ${myurl}  Set Variable   /crosswork/platform/alarms/v1/alarms/?type=device&_COND=and&severity=Critical,Major&_SORT=lastModifiedTimestamp.DESC
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	
	Should Be True  '${response.status_code}'=='200' or '${response.status_code}'=='206' 
    
	${alarms}    evaluate  json.loads($response.text)    json
	
	Set Test Variable    ${MSG}	--Device Alarms--
	FOR  ${item}  IN  @{alarms}
		Set Test Variable    ${MSG}    ${MSG}\n${item['displayName']}|${item['severity']}:${item['eventType']}:${item['srcObjectDisplayName']}
		Append To List  ${CW_DEVICE_ALARMS}	${item['displayName']}|${item['severity']}:${item['eventType']}:${item['srcObjectDisplayName']}
	END	

	Set Suite Variable  ${CW_DEVICE_ALARMS}

get-kpis

    ${myurl}  Set Variable   /crosswork/hi/v1/kpis
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CW_KPI}=    Create List	
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json

	FOR  ${item}  IN  @{json_response['kpis']['kpi']}
		#Set Test Variable    ${MSG}    ${MSG}\n[${item['category']}] ${item['kpi_name']}:${item['sensor_type']} 
		Append To List  ${CW_KPI}	[${item['category']}] ${item['kpi_name']}:${item['sensor_type']} 
	END	

	${NUM_KPI}	Get Length	${CW_KPI}
	Set Test Variable    ${MSG}    ${MSG}# KPIs: ${NUM_KPI}

	Set Suite Variable  ${CW_KPI}	

get-application-versions

    ${myurl}  Set Variable   /crosswork/platform/v2/capp/applicationsummary/query
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CW_APP_VERSIONS}=    Create List	
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Application Versions--
	FOR  ${item}  IN  @{json_response['application_summary_list']}
		Set Test Variable    ${MSG}    ${MSG}\n${item['application_data']['application_id']}:${item['application_data']['version']}	
		Append To List  ${CW_APP_VERSIONS}	${item['application_data']['application_id']}:${item['application_data']['version']}		
	END	

	Set Suite Variable  ${CW_APP_VERSIONS}	


validate-cw-versions

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cw-apps.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CW_APP_VERSIONS}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

get-application-health

    ${myurl}  Set Variable   /crosswork/platform/v2/cluster/app/health/list
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CW_APP_HEALTHY}=    Create List	
	@{CW_APP_DEGRADED}=    Create List	
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Application Health--
	
	FOR  ${item}  IN  @{json_response['app_health_summary']}
		
		${equal}  Run Keyword And Ignore Error	Should Be Equal As Strings	${item['health_summary']['state']}	Healthy
		
		IF	"${equal}[0]" == "PASS"
			Append To List  ${CW_APP_HEALTHY}	${item['health_summary']['obj_name']}
			Set Test Variable    ${MSG}    ${MSG}\n${item['health_summary']['obj_name']}:Healthy
			
		ELSE 
			Set Test Variable    ${MSG}    ${MSG}\n${item['health_summary']['obj_name']}:Degraded
			Append To List  ${CW_APP_DEGRADED}	${item['health_summary']['obj_name']}		
		END
	
		#Set Test Variable    ${MSG}    ${MSG}\n${item['application_data']['application_id']}:${item['application_data']['version']}	
		#Append To List  ${CW_APP_VERSIONS}	${item['application_data']['application_id']}:${item['application_data']['version']}		
	END	

	Set Suite Variable  ${CW_APP_DEGRADED}	
	Set Suite Variable  ${CW_APP_HEALTHY}	

validate-application-health

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${FAIL_COUNT}=  Get Length  ${CW_APP_DEGRADED}

	FOR  ${item}  IN  @{CW_APP_DEGRADED}
		Set Test Variable    ${MSG}    ${MSG}\nFAIL: [${ENV}]:${item} is Degraded
		Set Tags	FAIL		
	END

	Run Keyword If  ${FAIL_COUNT} > 0 
	...  fail   ${FAIL_COUNT} applications degraded. 
	
	FOR  ${item}  IN  @{CW_APP_HEALTHY}
		Set Test Variable    ${MSG}    ${MSG}\nPASS: [${ENV}]:${item} is Healthy
		Set Tags	PASS
	END

	Run Keyword If  ${FAIL_COUNT} == 0 
	...  pass execution   ${FAIL_COUNT} applications were listed as degraded.

validate-cnc-credentials

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cw-credentials.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CW_CREDENTIALS}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

validate-cnc-providers

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cw-providers.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CW_PROVIDERS}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  ${CW_PROVIDERS}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
			
		END
	END		

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

iap-app-list
    ${myurl}  Set Variable   /health/modules
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${response}   GET ON Session  logon  ${myurl}  headers=${headers}	expected_status=200

    ${RUNNING_APPS}    evaluate  json.loads($response.text)    json
	@{IAP_APP_VERSION}=    Create List
	@{IAP_APP_STATE}=    Create List	
	
	
    FOR    ${app}    IN    @{RUNNING_APPS}
		IF	"${app["type"]}" == "Application"
			Log  "adding " ${app["id"]}:${app["version"]}:${app["state"]} to list
			Append To List  ${IAP_APP_VERSION}	${app["id"]}:${app["version"]}
			Append To List  ${IAP_APP_STATE}	${app["id"]}:${app["state"]}			
		END
    END	
	
	Log List	${IAP_APP_VERSION}
	Log List	${IAP_APP_STATE}

	${APP_COUNT}=  Get Length  ${IAP_APP_VERSION}	
	Set Test Variable    ${MSG}	${APP_COUNT} Application(s) are detected	
	
	Set Suite Variable  ${IAP_APP_VERSION}	
	Set Suite Variable  ${IAP_APP_STATE}		

iap-adapter-list
    ${myurl}  Set Variable   /health/modules
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${response}   GET ON Session  logon  ${myurl}  headers=${headers}	expected_status=200

    ${RUNNING_ADAPTERS}    evaluate  json.loads($response.text)    json
	@{IAP_ADAPTER_VERSION}=    Create List
	@{IAP_ADAPTER_STATE}=    Create List	
	
	
    FOR    ${adapter}    IN    @{RUNNING_ADAPTERS}
		IF	"${adapter["type"]}" == "Adapter"
			Log  "adding " ${adapter["id"]}:${adapter["version"]}:${adapter["state"]} to list
			Append To List  ${IAP_ADAPTER_VERSION}	${adapter["id"]}:${adapter["version"]}
			Append To List  ${IAP_ADAPTER_STATE}	${adapter["id"]}:${adapter["state"]}			
		END
    END	
	
	Log List	${IAP_ADAPTER_VERSION}
	Log List	${IAP_ADAPTER_STATE}
	
	${ADAPTER_COUNT}=  Get Length  ${IAP_ADAPTER_VERSION}	
	Set Test Variable    ${MSG}	${ADAPTER_COUNT} Adapter(s) are detected

	Set Suite Variable  ${IAP_ADAPTER_VERSION}	
	Set Suite Variable  ${IAP_ADAPTER_STATE}	

iap-nso-ned-list	
    ${myurl}  Set Variable	/nso_manager/allNeds
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${response}   GET ON Session  logon  ${myurl}  headers=${headers}	expected_status=200

    ${NEDS}    evaluate  json.loads($response.text)    json
	
	${NEDS_COUNT}=  Get Length  ${NEDS}	

	Set Test Variable    ${MSG}	${NEDS_COUNT} NEDs were found.
	
	Set Suite Variable  ${NEDS}	
	
	@{NED_LIST}=    Create List	

    FOR    ${ned}    IN    @{NEDS}
		Set Test Variable    ${MSG}    ${MSG}\n${ned}
	END
	

iap-task-list	
    ${myurl}  Set Variable	/workflow_builder/tasks/list
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${response}   GET ON Session  logon  ${myurl}  headers=${headers}	expected_status=200

    ${RUNNING_TASKS}    evaluate  json.loads($response.text)    json

	@{MODULE_TASK_LIST}=    Create List
	@{MODULE_LIST}=    Create List	

    FOR    ${task}    IN    @{RUNNING_TASKS}
		Append To List  ${MODULE_TASK_LIST}  ${task["app"]}.${task["name"]}
	
		${RESP}=  Run Keyword And Ignore Error  List Should Not Contain Value  ${MODULE_LIST}  ${task["app"]}
		
		IF	"${RESP}[0]" == "PASS"
			Append To List  ${MODULE_LIST}  ${task["app"]}		
		END
		
    END
	
	Log List	${MODULE_TASK_LIST}
	Log List	${MODULE_LIST}
	
	${TASK_COUNT}=  Get Length  ${MODULE_LIST}	
	${TASK_TASK_COUNT}=  Get Length  ${MODULE_TASK_LIST}
	
	Set Test Variable    ${MSG}	${TASK_COUNT} Modules were found.
	Set Test Variable    ${MSG}	${MSG}\n${TASK_TASK_COUNT} Tasks/Methods were found.
	
	Set Suite Variable  ${MODULE_LIST}	
	Set Suite Variable  ${MODULE_TASK_LIST}	


	
valid-apps-version

	#log variables  level=INFO

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List			
	
	${appsVALID}  Load Data from File  RELEASES${/}${IAP_VER}${/}valid_apps.txt
	@{appsVALID}=    Split to lines  ${appsVALID}

	
	# Common list of apps
	FOR  ${item}  IN  @{appsVALID}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_APP_VERSION}  ${item}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: ${item}		
		Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
	END

	FOR  ${item}  IN  @{IAP_APP_VERSION}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END	

	# Environment specific list of apps
	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${CURDIR}${/}ENV${/}${ENV}${/}valid_apps.txt

	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_APP_VERSION}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
		END

	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}


iap-nso-ned-verify
	# Environment Level only, since it depends what is connected

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List			
	
	${NEDS_VALID}  Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}valid_nso_neds.txt
	@{NEDS_VALID}=    Split to lines  ${NEDS_VALID}


	FOR  ${item}  IN  @{NEDS_VALID}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${NEDS}  ${item}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: ${item}		
		Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:NED found in validation list, but not in system
	END

	FOR  ${item}  IN  @{NEDS}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${NEDS_VALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END	


	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are NEDS present that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll validations passed. Failures:${FAIL_COUNT}


valid-apps-status
 
	#log variables  level=INFO

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	
	@{appsVALID-RUNNING}=    Create List
	@{appsVALID-RUNNING-ENV}=    Create List	
	
	${appsVALID}  Load Data from File  RELEASES${/}${IAP_VER}${/}valid_apps.txt
	@{appsVALID}=    Split to lines  ${appsVALID}

	#Rebuild the applications list without the version and test for 'running'
	
	FOR  ${item}  IN  @{appsVALID}
		@{split}	Split String	${item}	:
		Log	${split[0]}
		Append To List	${appsVALID-RUNNING}	${split[0]}:RUNNING
	
	END
	
	# Common list of apps
	FOR  ${item}  IN  @{appsVALID-RUNNING}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_APP_STATE}  ${item}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: ${item}		
		Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
	END

	FOR  ${item}  IN  @{IAP_APP_STATE}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID-RUNNING}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END	

	# Environment specific list of apps
	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${CURDIR}${/}ENV${/}${ENV}${/}valid_apps.txt

	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_APP_STATE}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
		END


	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

###
valid-adapter-version

	#log variables  level=INFO

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List			
	
	${appsVALID}  Load Data from File  RELEASES${/}${IAP_VER}${/}valid_adapters.txt
	@{appsVALID}=    Split to lines  ${appsVALID}

	
	# Common list of apps
	FOR  ${item}  IN  @{appsVALID}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_ADAPTER_VERSION}  ${item}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: ${item}		
		Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
	END

	FOR  ${item}  IN  @{IAP_ADAPTER_VERSION}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END	

	# Environment specific list of apps
	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${CURDIR}${/}ENV${/}${ENV}${/}valid_adapters.txt

	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_ADAPTER_VERSION}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
		END


	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}


valid-adapter-status
 
	#log variables  level=INFO

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	
	@{appsVALID-RUNNING}=    Create List
	@{appsVALID-RUNNING-ENV}=    Create List	
	
	${appsVALID}  Load Data from File  RELEASES${/}${IAP_VER}${/}valid_adapters.txt
	@{appsVALID}=    Split to lines  ${appsVALID}

	#Rebuild the applications list without the version and test for 'running'
	
	FOR  ${item}  IN  @{appsVALID}
		@{split}	Split String	${item}	:
		Log	${split[0]}
		Append To List	${appsVALID-RUNNING}	${split[0]}:RUNNING
	
	END
	
	# Common list of apps
	FOR  ${item}  IN  @{appsVALID-RUNNING}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_ADAPTER_STATE}  ${item}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: ${item}		
		Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
	END

	FOR  ${item}  IN  @{IAP_ADAPTER_STATE}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID-RUNNING}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Not in valid list.
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END	

	# Environment specific list of apps
	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${CURDIR}${/}ENV${/}${ENV}${/}valid_adapters.txt

	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${IAP_ADAPTER_STATE}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
		END


	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  Differences between detected and actual applications were encountered.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  There are applications running that are not in the valid list.	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

module-test
	@{PASS}=    Create List		
	@{FAIL}=    Create List		
	${TASK_COUNT}  Set Variable  ${0}
	
    FOR    ${module}    IN    @{MODULE_LIST}	

		## Common module tests across all platforms
		
		Log  ${BASE}${/}unit-tests${/}modules${/}${module}e
		
		${res}  Run Keyword And Return Status   OperatingSystem.List Files In Directory  ${BASE}${/}unit-tests${/}modules${/}${module}
		${count}  Run Keyword If  ${res} == ${true}   Count Files In Directory  ${BASE}${/}unit-tests${/}modules${/}${module}
		
		@{files}  Run Keyword If  ${count} > 0     OperatingSystem.List Files In Directory  ${BASE}${/}unit-tests${/}modules${/}${module}
		
		FOR  ${file}  IN  @{files}
			${ext}  Split Extension  ${file}
			${TC}  Set Variable  ${ext}[0].IAP-Module-Test
			${LoadFile}  Set Variable  ${BASE}${/}unit-tests${/}modules${/}${module}${/}${file} 
			
			Import Resource   ${LoadFile}
			${RESP}=    Run Keyword And Ignore Error   ${TC}
			Append To List  ${${RESP}[0]}  ${${RESP}[0]X} : ${TC}:${module}:${RESP}[1]
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X} : ${module} | ${TC} | [MSG:${RESP}[1]]
			${TASK_COUNT}  Set Variable  ${TASK_COUNT+1}  
		END
		
	END

    FOR    ${module}    IN    @{MODULE_LIST}	

		
		${res}  Run Keyword And Return Status   OperatingSystem.List Files In Directory  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${module}
		${count}  Run Keyword If  ${res} == ${true}   Count Files In Directory  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${module}
		
		@{files}  Run Keyword If  ${count} > 0     OperatingSystem.List Files In Directory  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${module}
		
		FOR  ${file}  IN  @{files}
			${ext}  Split Extension  ${file}
			${TC}  Set Variable  ${ext}[0].IAP-Module-Test
			${LoadFile}  Set Variable  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${module}${/}${file} 
			
			Import Resource   ${LoadFile}
			${RESP}=    Run Keyword And Ignore Error   ${TC}
			Append To List  ${${RESP}[0]}  ${${RESP}[0]X} : ${TC}:${module}:${RESP}[1]
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X} : ${module} | ${TC} | [MSG:${RESP}[1]]
			${TASK_COUNT}  Set Variable  ${TASK_COUNT+1}  
		END
		
	END

	
	${FAIL_COUNT}=  Get Length  ${FAIL}
	${PASS_COUNT}=  Get Length  ${PASS}	
	
	Set Test Variable    ${MSG}    ${MSG}\n${TASK_COUNT} Application test(s) executed
	Set Test Variable    ${MSG}    ${MSG}\n${FAIL_COUNT} Application test(s) failed
	Set Test Variable    ${MSG}    ${MSG}\n${PASS_COUNT} Application test(s) passed	

	Log List  ${PASS}
	Log List  ${FAIL}	

	Run Keyword If  ${FAIL_COUNT} > 0  
	...	 fail  ${FAIL_COUNT} / ${TASK_COUNT} TASK Test(s) failed.


valid-tasks
	[Documentation]         This task will perform the following functions:
	...                     \n 1. Identify all the running methods (IAP Module methods) on the running system
	...						\n 2. Under the ``unit-tests`` directory, will look for another directory matching the ``module.method`` name
	...						\n 3. Load any ``.robot`` files in those directories and execute them	
	...                     \n Author: Simon Price
	
	[Tags]  IAPTASKS
    ${myurl}  Set Variable   status
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}

	${resp}  GET ON Session  logon  ${myurl}  expected_status=200 

	${json_data}  Parse Json  ${resp.text}
	${detected_host}  Set Variable  ${json_data["host"]}
	
	Log  ${detected_host}
	
	# Find a list of valid modules/methods (tasks) within IAP, and find any respective tests on disk.	
    
	${myurl}  Set Variable   /workflow_builder/tasks/list
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${response}   GET ON Session  logon  ${myurl}  headers=${headers}  expected_status=200
    
    ${MY_DATA_TABLE_VALUES}    evaluate  json.loads($response.text)    json

	@{list}=    Create List	
	

    FOR    ${task}    IN    @{MY_DATA_TABLE_VALUES}
 
		Log  "adding " ${task["name"]}:${task["summary"]} to @{list}
		Append To List  ${list}  ${task["app"]}.${task["name"]}

    END
	
	#Log List  ${list}

	@{PASS}=    Create List		
	@{FAIL}=    Create List		
	${TASK_COUNT}  Set Variable  ${0}
	
    FOR    ${task}    IN    @{list}	

		## Something needs to go here
		
		Log  ${BASE}${/}unit-tests${/}modules${/}${task}
		
		${res}  Run Keyword And Return Status   OperatingSystem.List Files In Directory  ${BASE}${/}unit-tests${/}modules${/}${task}
		${count}  Run Keyword If  ${res} == ${true}   Count Files In Directory  ${BASE}${/}unit-tests${/}modules${/}${task}
		
		@{files}  Run Keyword If  ${count} > 0     OperatingSystem.List Files In Directory  ${BASE}${/}unit-tests${/}modules${/}${task}
		
		FOR  ${file}  IN  @{files}
			${ext}  Split Extension  ${file}
			${TC}  Set Variable  ${ext}[0].IAP-Module-Test
			${LoadFile}  Set Variable  ${BASE}${/}unit-tests${/}modules${/}${task}${/}${file} 
			
			Import Resource   ${LoadFile}
			${RESP}=    Run Keyword And Ignore Error   ${TC}
			Append To List  ${${RESP}[0]}  ${${RESP}[0]X}:${TC}:${task}:${RESP}[1]
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}:${task} | ${TC} | [MSG:${RESP}[1]]
			${TASK_COUNT}  Set Variable  ${TASK_COUNT+1}  
		END
		
	END

    FOR    ${task}    IN    @{list}	
		#Log  ${task}
		#Log  "looking for tests for ${task}"
		
		${res}  Run Keyword And Return Status   OperatingSystem.List Files In Directory  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${task}
		${count}  Run Keyword If  ${res} == ${true}   Count Files In Directory  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${task}
		
		@{files}  Run Keyword If  ${count} > 0     OperatingSystem.List Files In Directory  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${task}
		
		FOR  ${file}  IN  @{files}
			${ext}  Split Extension  ${file}
			${TC}  Set Variable  ${ext}[0].IAP-Module-Test
			${LoadFile}  Set Variable  ${BASE}${/}ENV${/}${ENV}${/}unit-tests${/}modules${/}${task}${/}${file} 
			
			Import Resource   ${LoadFile}
			${RESP}=    Run Keyword And Ignore Error   ${TC}
			Append To List  ${${RESP}[0]}  ${${RESP}[0]X}:${TC}:${task}:${RESP}[1]
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}:${task} | ${TC} | [MSG:${RESP}[1]]
			${TASK_COUNT}  Set Variable  ${TASK_COUNT+1}  
		END
		
	END

	
	${FAIL_COUNT}=  Get Length  ${FAIL}
	${PASS_COUNT}=  Get Length  ${PASS}	
	
	Set Test Variable    ${MSG}    ${MSG}\n${TASK_COUNT} Application test(s) executed
	Set Test Variable    ${MSG}    ${MSG}\n${FAIL_COUNT} Application test(s) failed
	Set Test Variable    ${MSG}    ${MSG}\n${PASS_COUNT} Application test(s) passed	

	Log List  ${PASS}
	Log List  ${FAIL}	

	Run Keyword If  ${FAIL_COUNT} > 0  
	...	 fail  ${FAIL_COUNT} / ${TASK_COUNT} TASK Test(s) failed.

	Set Test Variable    ${MSG}    ${MSG}\n${TASK_COUNT} Application tests passed

Workflow-verify

    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   status
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}

	@{list}=    Create List	
	@{PASS}=    Create List		
	@{FAIL}=    Create List	


	### Run tests that are common across *all* platforms and environments (if any)

	${WF_DIR}  Set Variable  ${BASE}${/}wf-tests${/}common

	${res}  Run Keyword And Return Status   OperatingSystem.List Files In Directory  ${WF_DIR}
	
	IF  ${res} == False  # directory does not exist
			Set Test Variable    ${MSG}    ${MSG}\nERR: Directory does not exist [${WF_DIR}]
			fail  .. Exiting Test >
	END
	
	${count}  Run Keyword If  ${res} == ${true}   Count Files In Directory  ${WF_DIR}
	
	@{files}  Run Keyword If  ${count} > 0     OperatingSystem.List Files In Directory  ${WF_DIR}
	
	${NUM_TESTS}=  Get Length  ${files}
	
	Run Keyword If  ${NUM_TESTS} == 0 	Set Test Variable    ${MSG}    ${MSG}\nWARN: No tests were available
	
	FOR  ${file}  IN  @{files}
		${ext}  Split Extension  ${file}
		${TC}  Set Variable  ${ext}[0].IAP-Workflow-Test
		${LoadFile}  Set Variable  ${WF_DIR}${/}${file} 

		Import Resource   ${LoadFile}
		
		${RESP}=    Run Keyword And Ignore Error   ${TC}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X} : [Common] | ${file} | RESULT:[${RESP}[1]]
		Append To List  ${${RESP}[0]}  ${RESP}[0]: [Common]| ${file}| RESULT:[${RESP}[1]]
	
	END


	### Run tests that are *specific* to the IAP version. This is valid, since both workflows and the engine/schema both change

	${WF_DIR}  Set Variable  ${BASE}${/}RELEASES${/}${IAP_VER}${/}wf-tests

	${res}  Run Keyword And Return Status   OperatingSystem.List Files In Directory  ${WF_DIR}
	
	IF  ${res} == False  # directory does not exist
			Set Test Variable    ${MSG}    ${MSG}\nERR: Directory does not exist [${WF_DIR}]
			# We don't fail this time
	END
	
	${count}  Run Keyword If  ${res} == ${true}   Count Files In Directory  ${WF_DIR}
	
	@{files}  Run Keyword If  ${count} > 0     OperatingSystem.List Files In Directory  ${WF_DIR}
	
	${NUM_TESTS}=  Get Length  ${files}
	
	Run Keyword If  ${NUM_TESTS} == 0 	Set Test Variable    ${MSG}    ${MSG}\nWARN: No tests were available
	
	FOR  ${file}  IN  @{files}
		${ext}  Split Extension  ${file}
		${TC}  Set Variable  ${ext}[0].IAP-Workflow-Test
		${LoadFile}  Set Variable  ${WF_DIR}${/}${file} 

		Import Resource   ${LoadFile}
		
		${RESP}=    Run Keyword And Ignore Error   ${TC}
		Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X} : [${IAP_VER}] | ${file} | RESULT:[${RESP}[1]]
		Append To List  ${${RESP}[0]}  ${RESP}[0]: [${IAP_VER} ]| ${file}| RESULT:[${RESP}[1]]
	
	END

	### Now finalise the results into one blob
	
	${FAIL_LENGTH}=  Get Length  ${FAIL}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	
	Run Keyword If  ${FAIL_LENGTH} > 0  
	...  fail  ${FAIL_LENGTH} / ${count} WORKFLOW Test(s) failed.	


Retrieve workflow information
	[Tags]  Workflow
	[Documentation]	Retrieves Pronghorn workflow and parses the task tree for the task names
	
	Log Variables  level=TRACE
	${headers}  Create Dictionary   Content-type=application/json 	
	${wf}  GET ON Session  logon  ${wf}  headers=${headers} 
	should be equal as strings  ${wf.status_code}  200
	${tasks}  Get Json Value  ${wf.text}  /tasks

	${json_data}  Parse Json  ${tasks}  # This is now in JSON Format
	
	log  ${json_data}
	
	${keys}  Get Dictionary Keys	 ${json_data}

	${output}  create dictionary 
	set suite variable  ${output}

	:FOR  ${key}  IN  @{keys}
	\  ${dict}  get from dictionary  ${json_data}  ${key}
	\  ${names}  get dictionary values  ${dict}
	\  log  ${names}
	\  	${wfName}  Evaluate  $dict.get("name","undefined")
	\  	${wfType}  Evaluate  $dict.get("type","undefined")
	\  	${wfDescr}  Evaluate  $dict.get("description","undefined")
	
	\  	log to console  ${EMPTY}Task:${wfName},Type:${wfType},Description:${wfDescr}
	\  	Set To Dictionary    ${output}    ${wfName}	Type:${wfType},Description:${wfDescr}


Get-wf-details
	[Arguments]   ${wfid}
	# Find job details using different methods
	
	IF	"${IAP_VER}" == "2020.1.11"
		${status}	Run Keyword	Get-wf-details-v1	${wfid}
	ELSE
		${status}	Run Keyword	Get-wf-details-v2	${wfid}
	END
	RETURN  ${status}
	
Get-wf-details-v2
	[Documentation]	Retrieves Pronghorn workflow and parses the task tree for the task names
	[Tags]  Workflow
	[Arguments]   ${wfid}
	${wfbase}  Set Variable 	/workflow_engine/job/${wfid}/details

	${headers}  Create Dictionary   Content-type=application/json 	
	${wfres}  GET ON Session  logon  ${wfbase}  headers=${headers}	expected_status=200 

	${status}  Get Json Value  ${wfres.text}  /status

	RETURN  ${status}
	
	
Get-wf-details-v1
	[Documentation]	Retrieves Pronghorn workflow and parses the task tree for the task names
	[Tags]  Workflow
	[Arguments]   ${wfid}
	${wfbase}  Set Variable 	/workflow_engine/job/${wfid}/deep

	${headers}  Create Dictionary   Content-type=application/json 	
	${wfres}  GET ON Session  logon  ${wfbase}  headers=${headers}	expected_status=200

	${RESULT}  Evaluate  json.loads($wfres.text)	json

	${status}	Set Variable	${RESULT[0]['status']} 	

	RETURN  ${status}	
	
Logon to CNC
	[Documentation]  Get Crosswork token
	[arguments]	${data}
	Log Variables  level=TRACE	
	
	${data}  evaluate  json.loads($data)    json
	
	${serverURL}	Set Variable	${data["protocol"]}://${data["host"]}:${data["port"]}

	${auth}			Set Variable 	{"username":"${data["auth"]["username"]}","password":"${data["auth"]["password"]}"}
	
	${headers}  Create Dictionary   Content-type=application/x-www-form-urlencoded 

	Create Session    alias=cw    url=${serverURL} 
	
	${auth}	Set Variable	/crosswork/sso/v1/tickets?username=${data["auth"]["username"]}&password=${data["auth"]["password"]}
	${tgt}	Set Variable	/crosswork/sso/v1/tickets

	${payload}			Set Variable			service=https://1.2.3.4/app-dashboard/app-dashboard
	
	${resp}		RequestsLibrary.POST ON Session	cw	${serverURL}${auth}	headers=${headers}  expected_status=201	verify=${False}
	
	${resp2}	RequestsLibrary.POST ON Session	cw	${serverURL}${tgt}/${resp.text}	headers=${headers}  expected_status=200	verify=${False}	data=${payload}
	
	${token}  set variable  ${resp2.text}
	set suite variable  ${token}
	log	${token}

	Set Test Variable    ${MSG}    ${MSG}HOST: ${serverURL}
	Set Test Variable    ${MSG}    ${MSG}\nUSER: ${data["auth"]["username"]}	
	Set Test Variable    ${MSG}    ${MSG}\nToken: ${token}

	
Positive Tests

	Execute Positive Test Cases   Uni-pos_tests.txt  post_tests

Order Assurance Service
    [Tags]  xxPronghorn

    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    #${wfinputs}  Set Variable  {"description":"Demonstration","variables":{"Notification_type":"a","join":"/","str2":"c"}}
    #${wfinputs}  Set Variable  {"description":"Demonstration","variables":{"instance_data":{"notification_type":"error","device":"s-1-100"}}}

    #${wfinput}  run keyword  Data Load  LoadFile=dataload-cramer.txt  device=${device}  notification=error

   ${wfinput}=    catenate
   ...  {
   ...  "description": "${now}",
   ...  "variables": {
   ...      "notificationType": "${notificationType}",
   ...      "serviceName": "${serviceName}",
   ...      "device":"${device}",
   ...      "actionType":"${actionType}",
   ...      "serviceURL":[{"portInfo":"http://nso-service.telstra.com/api/running/devices/device/${device}/config:ios/interface/GigabitEthernet0%2F3"},{"lagInfo":"http://nso-service.telstra.com/api/running/devices/device/${device}/config:ios/interface/GigabitEthernet0%2F3"}]
   ...  }
   ...  }

    ${wfinput}  replace variables   ${wfinput}
    
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200
	#${wf}  Get Request  logon  ${wf}?token=${token}  headers=${headers} 
	#should be equal as strings  ${wf.status_code}  200
	#${tasks}  Get Json Value  ${wf.text}  /tasks    

Create AU Service
    [Tags]  xxAU

    ${myurl}  Set Variable   workflow_engine/startJob/0_AU-Service-Remote
    ${headers}  Create Dictionary   Content-type=application/json 	

    ${wfinput}  run keyword  Data Load AU  LoadFile=dataload-auservicev2.txt  device=${device}  vrfname=${vrfname}  asnumber=${asnumber}  vlanid=${vlanid}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200
	#${wf}  Get Request  logon  ${wf}?token=${token}  headers=${headers} 
	#should be equal as strings  ${wf.status_code}  200
	#${tasks}  Get Json Value  ${wf.text}  /tasks    


Invalid State
    [Tags]  invalid
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  physical-modify.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  PHYSICAL-STATE-CHANGE
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200    

Create LAG and Physical Interfaces
    [Tags]  lagpi
    ${startTime}  Run Keyword  Get NOW time
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${LoadFile}  set variable  lagpi.txt
    ${description}  set variable    1 Lag 2 Physical
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  LAG-PHYSICAL-CREATE
	${LoadData}  Load Data from File  lagpi.txt
    ${endTime}  Run Keyword  Get NOW time    
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200      

Create LAG and Physical Interfaces 2
    [Tags]  lagpi
    ${startTime}  Run Keyword  Get NOW time
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${LoadFile}  set variable  lagpi2.txt
    ${description}  set variable    1 Lag 2 Physical v2
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  LAG-PHYSICAL-CREATE
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200
    
    
Create LAG and Physical Modify
    [Tags]  lagpi
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${LoadFile}  set variable  lag-physical-modify.txt
    ${description}  set variable    Modify LAG and Physical 1
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  LAG-PHYSICAL-MODIFY
	${LoadData}  Load Data from File  lag-physical-modify.txt
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200
    
Test Assurance
    
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${LoadFile}  set variable  lag-physical-modify.txt
    ${description}  set variable    Modify LAG and Physical 1
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  LAG-PHYSICAL-MODIFY
	${LoadData}  Load Data from File  lag-physical-modify.txt
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200       
    

Create Physical Interface 
    [Tags]  picreate
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  physical-create.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  PHYSICAL-CREATE
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200

Modify Physical Interface
    [Tags]  pimod
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  physical-modify.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  PHYSICAL-MODIFY
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200  
    
    
Modify Physical Interface State
    [Tags]  pimod
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  physical-modify.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  PHYSICAL-STATE-MODIFY
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200      
    
    
l3vpn add endpoint
    [Tags]  vpnepadd
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  endpoint-add.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  MOBL3VPN-ENDPOINT-ADD
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200
    
    
l3vpn add Remove
    [Tags]  vpnepdel
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  endpoint-add.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  MOBL3VPN-ENDPOINT-DELETE
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200    
    
    
l3vpn modify endpoint
    [Tags]  vpnepmodify
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  endpoint-add.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  MOBL3VPN-ENDPOINT-MODIFY
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200   

VPN Add Subinterface  
    [Tags]  vpnsifadd
    ${startTime}  Run Keyword  Get NOW time  
    ${myurl}  Set Variable   workflow_engine/startJob/Assurance-v05
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${description}  set variable    ${TEST NAME}
    ${LoadFile}  set variable  subinterface-add.txt   
    
	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	${actiontype}  set variable  MOBL3VPN-SUBINTERFACE-ADD
	${LoadData}  Load Data from File  ${LoadFile}
    ${endTime}  Run Keyword  Get NOW time   
	${LoadData}  replace variables   	${LoadData}
    log to console  ${LoadData}

	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${LoadData}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200     

Create LAGv2
    [Tags]  xxlagv2  

    ${myurl}  Set Variable   workflow_engine/startJob/_NODELETE-Assurance
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle.txt  device=${device}   iftype=${iftype}  ifid1=${ifid1}  ifid2=${ifid2}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200  

Create LAGv3
    [Tags]  xxlagv3

    ${myurl}  Set Variable   workflow_engine/startJob/_NODELETE-Assurance
    ${headers}  Create Dictionary   Content-type=application/json 	
    ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle2.txt  device=${device}   iftype=${iftype}  ifid1=${ifid1}  ifid2=${ifid2}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 

	should be equal as strings  ${resp.status_code}	 200 

Create AU Service auto
    [Tags]  xxlag
    
    ${myurl}  Set Variable   workflow_engine/startJob/0_AU-Service-Remote
    ${headers}  Create Dictionary   Content-type=application/json 
    log to console  "auto loop"
    ${fail}=  Set Variable  0
    :FOR  ${index}  IN RANGE  ${maxNum}
    \  ${vrfname}  Set Variable  W_S0000${index}R
    \  ${sifipaddr}  Set Variable  10.32.128.${index}
    \  ${wfinput}  run keyword  Data Load AU  LoadFile=dataload-auservicev2.txt  vrfname=${vrfname}  asnumber=${asnumber}  vlanid=${vlanid}  parentid=${parentid}  sifipaddr=${sifipaddr}
    \  ${passed}  run keyword and return status  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers}
    \  log to console  looping ${index}
    \  sleep  ${delay}
    \  Continue For Loop If  ${passed}
    \  ${fail}=  ${fail} + 1
    
    ${success}=  Set Variable  ${maxNum} - ${fail}
    Log Many   Success:  ${success}
    Log Many   fail:  ${fail}

Create LAG Auto
    [Tags]  newlag
    
    ${myurl}  Set Variable   workflow_engine/startJob/_NODELETE-Assurance
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${fail}=  Set Variable  0
    :FOR  ${index}  IN RANGE  ${maxNum}
    \  ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifidSTART}${index}  parentid=${parentidSTART}${index}
    \  ${passed}  run keyword and return status  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers}
    \  log to console  looping ${index}
    \  sleep  ${delay}
    \  Continue For Loop If  ${passed}
    \  ${fail}=  ${fail} + 1
    ${success}=  Set Variable  ${maxNum} - ${fail}
    Log Many   Success:  ${success}
    Log Many   fail:  ${fail}
    
    
Create PHY FullyAuto
    [Tags]  phy
    
    ${myurl}  Set Variable   workflow_engine/startJob/0_PHY-IF-CREATE-Auto
    ${headers}  Create Dictionary   Content-type=application/json 
    
    ${fail}=  Set Variable  0
    :FOR  ${index}  IN RANGE  ${maxNum}
    \  ${wfinput}  run keyword  Data Load Interface  LoadFile=dataload-interface.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifidSTART}${index}  parentid=${parentidSTART}${index}
    \  ${passed}  run keyword and return status  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers}
    \  log to console  looping ${index}
    \  sleep  ${delay}
    \  Continue For Loop If  ${passed}
    \  ${fail}=  ${fail} + 1
    ${success}=  Set Variable  ${maxNum} - ${fail}
    Log Many   Success:  ${success}
    Log Many   fail:  ${fail}    

Create LAG x
    [Tags]  LAG

    ${myurl}  Set Variable   workflow_engine/startJob/0_LAG-CREATE-Auto
    ${headers}  Create Dictionary   Content-type=application/json 	

    ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifid}  parentid=5001
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 

    #2
    ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=0/0/0/2  parentid=5002
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 
    
    #3
    ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=0/0/0/3  parentid=5003
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 
    
    #4
    ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=0/0/0/4  parentid=5004
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 
    
    #5
    ${wfinput}  run keyword  Data Load Bundle  LoadFile=dataload-bundle.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=0/0/0/5  parentid=5005
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers}     

	should be equal as strings  ${resp.status_code}	 200
	#${wf}  Get Request  logon  ${wf}?token=${token}  headers=${headers} 
	#should be equal as strings  ${wf.status_code}  200
	#${tasks}  Get Json Value  ${wf.text}  /tasks    

Create Interfaces in LAG 
    [Tags]  Interfaces

    ${myurl}  Set Variable   workflow_engine/startJob/0_PHY-IF-CREATE-Auto
    ${headers}  Create Dictionary   Content-type=application/json 	

    ${wfinput}  run keyword  Data Load Interface  LoadFile=dataload-interface.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifid}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 

    #1
    ${wfinput}  run keyword  Data Load Interface  LoadFile=dataload-interface.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifid}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 
    #2
    ${wfinput}  run keyword  Data Load Interface  LoadFile=dataload-interface.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifid}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 
    #3
    ${wfinput}  run keyword  Data Load Interface  LoadFile=dataload-interface.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifid}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 
    #4
    ${wfinput}  run keyword  Data Load Interface  LoadFile=dataload-interface.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifid}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 
    $5
    ${wfinput}  run keyword  Data Load Interface  LoadFile=dataload-interface.txt  device=${device}  notificationType=info  iftype=${iftype}  ifid=${ifid}  parentid=${parentid}
	${resp}  POST Request  logon  ${myurl}?token=${token}  data=${wfinput}  headers=${headers} 


	should be equal as strings  ${resp.status_code}	 200


Log Output
	[Arguments]   ${output}
    return
	Log Dictionary  ${output}


Data Load Interface
	[Arguments]  ${LoadFile}=${LoadFile}  ${device}=${device}  ${notificationType}=${notificationType}  ${iftype}=${iftype}  ${ifid}=${ifid}  ${parentid}=${parentid}

	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	
	${LoadData}  Load Data from File  ${LoadFile} 
	${LoadData}  replace variables   	${LoadData}
        
	   
	RETURN  ${LoadData}	

Data Load Bundle
	[Arguments]  ${LoadFile}=${LoadFile}  ${device}=${device}   ${iftype}=${iftype}  ${ifid1}=${ifid1}  ${ifid2}=${ifid2}  ${parentid}=${parentid}

	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	
	${LoadData}  Load Data from File  ${LoadFile} 
	${LoadData}  replace variables   	${LoadData}
        
	   
	RETURN  ${LoadData}	

Data Load
	[Arguments]  ${LoadFile}=dataload-cramer.txt  ${device}=${device}  ${notification}=info

	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	
	${LoadData}  Load Data from File  ${LoadFile} 
	${LoadData}  replace variables   	${LoadData}
        
	
	RETURN  ${LoadData}
    
Data Load AU
	[Arguments]  ${LoadFile}=dataload-cramer.txt  ${device}=${device}  ${notificationType}=${notificationType}  ${vrfname}=${vrfname}  ${asnumber}=${asnumber}  ${vlanid}=${vlanid}  ${parentid}=${parentid}  ${sifipaddr}=${sifipaddr}

	OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	
	${LoadData}  Load Data from File  ${LoadFile} 
	${LoadData}  replace variables   	${LoadData}
        	   
	RETURN  ${LoadData}	    


Load Data from File
	[arguments]  ${loadFile}
	${LoadData}   OperatingSystem.Get File  ${loadFile}
	RETURN  ${LoadData}

Pronghorn Save devices
    [Tags]  save
    ${myurl}  Set Variable   service_management/getinstance/%2FTelstra%3Anetwork%2Finfrastructure%2Fdevices%3Adevices/${device}
    ${headers}  Create Dictionary   Content-type=application/json     
    ${wfinput}=    catenate
    ...   {
    ...    "description": "Create Interfaces for bundle ${parentid} on ${device}",
    ...    "variables": {
    ...        "instance_data": {"device":"${device}"}
    ...   }}
    
    ${response}   Get Request  logon  ${myurl}?token=${token}  headers=${headers}
    Create File  ${EXECDIR}/devices-package-latest-${device}.json  ${response.text}


Pronghorn Save l3vpn
    [Tags]  vpnsave
    ${myurl}  Set Variable   IntegrationAPI/v1/services-summary/l3vpns
    ${headers}  Create Dictionary   Content-type=application/json
    
    ${response}   Get Request  logon  ${myurl}?token=${token}  headers=${headers}
    Remove File  ${EXECDIR}/l3vpn-summary.json
    Create File  ${EXECDIR}/l3vpn-summary.json  ${response.text}
    
    #log to console  ${response.text}[response]
    
    ${json_data}  Parse Json  ${response.text}
    
    log to console  ${json_data}
   
    #${keys}  Get Dictionary Keys  {json_data["response"]}
    
    :FOR  ${key}  IN  @{json_data["response"]}
    \  ${servicekey}  Set Variable  ${key["key_value"]}
    \  log to console  ${servicekey}
    #\  ${myurl}  Set Variable   service_management/getinstance/%2FTelstra%3Anetwork%2Fedge-#service%2Fvpn%2Fl3vpnservice%3Al3vpnservice/${servicekey}
    \  ${myurl}  Set Variable   service_management/getinstance/%2FTelstra%3Anetwork%2Fedge-service%2Fvpn%2Fl3vpninfracfs%3Al3vpninfracfs/${servicekey}
    \  log to console  ${myurl}
    \  ${response}   Get Request  logon  ${myurl}?token=${token}  headers=${headers}
    \  Create File  ${EXECDIR}/l3vpn-save-${servicekey}.json  ${response.text}
    

Pronghorn Restore devices
    [Tags]  restore
    ${myurl}  Set Variable   workflow_engine/startJob/_NODELETE-Assurance
    ${headers}  Create Dictionary   Content-type=application/json 
    ${LoadFile}  Set Variable   ${EXECDIR}/devices-package-latest-${device}.json

    OperatingSystem.File Should Exist  ${LoadFile}  MSG=Template [${LoadFile}] was not found!
	
	${LoadData}  Load Data from File  ${LoadFile}
    
    ${restoreData}=    catenate
    ...   {
    ...    "description": "Restore ${device} data",
    ...    "variables": {
    ...        "instance_data": ${LoadData}
    ...   }}
    
    
    ${response}   POST Request  logon  ${myurl}?token=${token}  data=${restoreData}  headers=${headers}
    should be equal as strings  ${response.status_code}	 200

Workflow-test-remove

	# Find the workflows first using different methods
	
	IF	"${IAP_VER}" == "2020.1.11"
		Run Keyword	Workflow-test-remove-v1
	ELSE
		Run Keyword	Workflow-test-remove-v2
	END
	
Workflow-test-remove-v1

	# Find workflows .. 
    ${myurl}  Set Variable   /workflow_engine/workflows/search
	${search}	Set Variable	{"options":{"skip":0,"limit":100,"sort":{"name":1},"fields":{"name":1,"created":1,"created_by":1,"last_updated":1,"last_updated_by":1,"tags":1},"query":{"$or":[{"type":"automation"},{"type":null}],"name":{"$regex":"^${now}","$options":"i"}},"expand":["created_by","last_updated_by","tags"],"entity":"workflows"}}
	${search}	evaluate  json.loads($search)    json

	${response}  POST ON Session  logon  ${myurl}  json=${search}  expected_status=200
	
	${resp}  evaluate  json.loads($response.text)    json
	
	IF	${${resp['total']}} > ${0}
	
		Set Test Variable    ${MSG}    ${MSG}${resp['total']} Workflows were run - attempting to delete them.
		FOR  ${item}  IN  @{resp['results']}
			Log	${item['name']}

			${myurl}  Set Variable   /workflow_builder/workflows/delete/${item['name']}	
			${response}  DELETE ON Session  logon  ${myurl}	expected_status=200
			${resp}  evaluate  json.loads($response.text)    json		
			Set Test Variable    ${MSG}    ${MSG}\nTest Workflow: ${item['name']}:DELETED		

		END

	ELSE
			
			Set Test Variable    ${MSG}    No workflows need to be deleted.

	END
	


Workflow-test-remove-v2

	# Find workflows .. 
    ${myurl}  Set Variable   /search/find
	${search}	Set Variable	{"data":{"text":"${now}"}}
	${search}	evaluate  json.loads($search)    json

	${response}  POST ON Session  logon  ${myurl}  json=${search}  expected_status=200
	
	${resp}  evaluate  json.loads($response.text)    json
	
	IF	${${resp['totalCount']}} > ${0}
	
		Set Test Variable    ${MSG}    ${MSG}${resp['totalCount']} Workflows were run - attempting to delete them.
		FOR  ${item}  IN  @{resp['results'][0]['results']}
			Log	${item['name']}

			${myurl}  Set Variable   /workflow_builder/workflows/delete/${item['name']}	
			${response}  DELETE ON Session  logon  ${myurl}	expected_status=200
			${resp}  evaluate  json.loads($response.text)    json		
			Set Test Variable    ${MSG}    ${MSG}\nTest Workflow: ${item['name']}:DELETED		

		END

	ELSE
			
			Set Test Variable    ${MSG}    No workflows need to be deleted.

	END
	

jobs-test-remove

	# Find the jobs first using different methods
	
	IF	"${IAP_VER}" == "2020.1.11"
		Run Keyword	jobs-test-remove-v1
	ELSE
		Run Keyword	Workflow-test-remove-v2
	END


jobs-test-remove-v1

	# Find jobs .. 
    ${myurl}  Set Variable   /workflow_engine/jobs/search


	${search_payload}	Set Variable	{"options":{"skip":0,"limit":1000,"sort":{"metrics.start_time":-1},"fields":{"name":1,"description":1,"parent":null,"last_updated":null,"metrics":1,"status":1,"error":1},"query":{"name":{"$regex":"${now}.*","$options":"i"}},"expand":["error"],"entity":"workflows"}}

	${search_payload}  evaluate  json.loads($search_payload)    json

	${response}  POST ON Session  logon  ${myurl}  json=${search_payload}  expected_status=200
	
	${resp}  evaluate  json.loads($response.text)    json
	
	
	IF	${${resp['total']}} > ${0}
	
		FOR	${item}	IN	@{resp['results']}
			Log	${item['name']} : ${item['_id']}
			
			# Cancel Job, don't care if it works or not
			${myurl}  Set Variable   /workflow_engine/cancelJob		
			${body}  Set Variable	{"job_id":"${item['_id']}"}
			${body}	evaluate  json.loads($body)    json
			${response}	Run Keyword And Ignore Error  POST ON Session  logon  ${myurl}  json=${body}
			${res}  Get-wf-details  ${item['_id']}

			Set Test Variable    ${MSG}    ${MSG}\nTest Job: ${item['name']}:STATUS [${res}]			
		
		END
	
	ELSE
	
			Set Test Variable    ${MSG}    ${MSG}No Test Jobs need to be cancelled.
	END


jobs-test-remove-v2

	# Find jobs .. 
    ${myurl}  Set Variable   /workflow_engine/jobs/search


	${search_payload}	Set Variable	{"options":{"skip":0,"limit":1000,"sort":{"metrics.start_time":-1},"fields":{"name":1,"description":1,"parent":null,"last_updated":null,"metrics":1,"status":1,"error":1},"query":{"name":{"$regex":"${now}.*","$options":"i"}},"expand":["error"],"entity":"workflows"}}

	${search_payload}  evaluate  json.loads($search_payload)    json

	${response}  POST ON Session  logon  ${myurl}  json=${search_payload}  expected_status=200
	
	${resp}  evaluate  json.loads($response.text)    json
	
	
	IF	${${resp['total']}} > ${0}
	
		FOR	${item}	IN	@{resp['results']}
			Log	${item['name']} : ${item['_id']}
			
			# Cancel Job, don't care if it works or not
			${myurl}  Set Variable   /workflow_engine/cancelJob		
			${body}  Set Variable	{"job_id":"${item['_id']}"}
			${body}	evaluate  json.loads($body)    json
			${response}	Run Keyword And Ignore Error  POST ON Session  logon  ${myurl}  json=${body}
			${res}  Get-wf-details  ${item['_id']}

			Set Test Variable    ${MSG}    ${MSG}\nTest Job: ${item['name']}:STATUS [${res}]			
		
		END
	
	ELSE
	
			Set Test Variable    ${MSG}    ${MSG}No Test Jobs need to be cancelled.
	END		

Suite Teardown

	[Tags]  Pronghorn
	[Documentation]  Dispose of Sessions
	
	Delete All sessions


Suite Setup	

	Create Hosts
	Get Current DTTM