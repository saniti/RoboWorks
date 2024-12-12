*** Keywords ***

Get Current DTTM
	[Documentation]			Gets the current time as a reference
	...						\nSuite Variables: ``now``
	...						
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	log  LOGLEVEL:${LOG LEVEL}	# Print the currently loglevel
	${now}  get current date  result_format=%Y%m%d-%H%M%S
	set suite variable  ${now}
	log to console  \nCurrent Time: ${now}
    
Get NOW time
	${mynow}  get current date  result_format=%Y%m%d-%H%M%S
    RETURN  ${mynow}  

Load Data from File
	[arguments]  ${loadFile}
	${LoadData}   OperatingSystem.Get File  ${loadFile}
	RETURN  ${LoadData}

get-cnc-platform
	[Documentation]			Retrieves current running information on the CNC Platform
	...						\nSuite Variables: ``CNC_PLATFORM``
	...						
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   /crosswork/platform/v1/node-manager/clusters
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CNC_PLATFORM}=    Create List	
	
	@{FIELDS}=	Create List	SchemaVersion	CNC_VM_Image		ClusterIPStack	ManagementVIP	ManagementIPNetmask	ManagementIPGateway	DataVIP	DataIPNetmask	DataIPGateway	DomainName	NTP	DNS	RamDiskSize	ThinProvisioned	Timezone
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Platform Specs--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['CwClusterAndActions']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for Platform Specs\n
		fail	Test failed.
	ELSE 
		FOR  ${item}  IN  @{FIELDS}
			${search}	Set Variable 	$..${item}
			${data}	Get Value From Json    ${json_response['CwClusterAndActions']}    ${search}

			Set Test Variable    ${MSG}    ${MSG}${item}:${data}\n
			Append To List  ${CNC_PLATFORM}	${item}:${data}
			
		END 

	END

	Set Suite Variable  ${CNC_PLATFORM}	
	

validate-cnc-platform
	[Documentation]			Validates the platform spec based on the suite variable of ``CNC_PLATFORM``
	...						
	...						\nValidation file(s): cnc-platform.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-platform.txt
	
	Set Test Variable    ${MSG}	--Validate CNC Platform--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_PLATFORM}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  @{CNC_PLATFORM}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Appears to be a new entry not in the validation list.\n
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} validation(s) failed for CNC Platform configuration.
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

get-cnc-nodes
	[Documentation]			Retrieves current running information on the CNC nodes
	...						\nSuite Variables: ``CNC_NODES``
	...						
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   /crosswork/platform/v2/cluster/dc/node/summary/list
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CNC_NODES}=    Create List
	@{CNC_NODES_HEALTH}=    Create List	
	
	@{FIELDS}=	Create List	vm_name	node_id		node_type	node_resource.cpu_summary.total	node_resource.memory_summary.total	node_resource.disk_summary.total
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Node Info--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['node_summary']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for Node Info\n
		fail	Test failed.	
	
		FOR  ${data}  IN  @{json_response['node_summary']}
			
			${key}  Set Variable   ${data['node_name']}
			
			FOR  ${item}  IN  @{FIELDS}
				${search}	Set Variable 	$.${item}
				
				${values}	Get Value From Json   ${data}    ${search}

				Set Test Variable    ${MSG}    ${MSG}${key}|${item}:${values}\n
				Append To List  ${CNC_NODES}	${key}|${item}:${values}
				
			END 
			
		END

	END

	Set Suite Variable  ${CNC_NODES}	
	Set Suite Variable  ${CNC_NODES_HEALTH}	

get-cnc-entitlement
	[Documentation]			Retrieves CNC Entitlements
	...						\nSuite Variables: ``CNC_ENTITLEMENTS``
	...						
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   /crosswork/clms/v1/onboard-list
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CNC_ENTITLEMENTS}=    Create List	
	
	@{FIELDS}=	Create List		name	version
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Entitlements--\n

	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Entitlements\n
		fail	Test failed.	
	ELSE
		FOR  ${item}  IN  @{json_response}
			${entitlement}=	Set Variable   ${item['display_name']}
			
			FOR  ${ent}  IN  @{FIELDS}
				Log	${item}
				${search}	Set Variable 	$..${ent}
				${data}	Get Value From Json    ${item['entitlements']}    ${search}

				Set Test Variable    ${MSG}    ${MSG}${entitlement}|${ent}:${data}\n
				Append To List  ${CNC_ENTITLEMENTS}	${entitlement}|${ent}:${data}
				
			END 		
			
		END

	END
	
	Set Suite Variable  ${CNC_ENTITLEMENTS}	


validate-cnc-entitlement
	[Documentation]			Validates the CNC entitlements based on the suite variable of ``CNC_ENTITLEMENTS``
	...						
	...						\nValidation file(s): cnc-entitlements.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-entitlements.txt
	
	Set Test Variable    ${MSG}	--Validate CNC Entitlements--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_ENTITLEMENTS}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  @{CNC_ENTITLEMENTS}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}WARN: ${item} Appears to be a new entry not in the validation list.\n
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
			
		END
	END		

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} validation(s) failed for CNC entitlements
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll entitlements validated:${FAIL_COUNT} Errors.
 

get-cnc-licensing
	[Documentation]			Retrieves CNC Entitlements
	...						\nSuite Variables: ``CNC_LICENSING``
	...						
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   /crosswork/clms/v1/license-info
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	${payload}	Set Variable	{"product_id":"CNC"}	
	${payload_json}	evaluate  json.loads($payload)    json	
	
	@{CNC_LICENSING}=    Create List	
	@{FIELDS_REGISTRATION}=	Create List	summary	registration_status

	@{FIELDS_ENTITLEMENT}=	Create List	display_name	entitlement_version	enforce_mode	requested_count

   ${description}  set variable    ${TEST NAME}

	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	
	Set Test Variable    ${MSG}	--CNC Licensing--\n


	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Licensing\n
		fail	Test failed.	

	ELSE 

		${key1}	Get Value From Json     ${json_response}     $.reservation_status
		${key2}	Get Value From Json     ${json_response}     $.smart_account_name	

		${registration_summary}	Get Value From Json     ${json_response}     $.registration_summary	

		Set Test Variable    ${MSG}    ${MSG}\n--- Licensing | Status:${key1} | Account:${key2} ---\n

		FOR  ${reg}  IN  @{FIELDS_REGISTRATION}	
			${search}	Set Variable 	$.${reg}
			${data}	Get Value From Json    @{registration_summary}    ${search}
			Set Test Variable    ${MSG}    ${MSG}${reg} | ${data}[0]\n
		END

		FOR  ${entitlement}  IN  @{json_response['entitlement_usage']}	
			
			Set Test Variable    ${MSG}    ${MSG}\n--- ${entitlement['description']} --- \n
			FOR  ${ent}  IN  @{FIELDS_ENTITLEMENT}	
				${search}	Set Variable 	$.${ent}
				${data}	Get Value From Json    ${entitlement}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${ent} | ${data}[0]\n
			END		

		END
	END	

	Set Suite Variable  ${CNC_LICENSING}	


DEPRECATED-get-service-types
	[Documentation]			DEPRECATED do not use
	...						
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}

	
    ${description}  set variable    ${TEST NAME}
	@{CNC_SERVICE_TYPES}=    Create List	
    ${myurl}  Set Variable   /crosswork/nbi/cat-inventory/v1/restconf/operations/cat-inventory-rpc:get-available-service-types

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--NSO Service Types--
	
	FOR  ${item}  IN  @{json_response['cat-inventory-rpc:output']['get-available-service-types-response']['service-type-info']}
		Set Test Variable    ${MSG}    ${MSG}\n${item['service-type-label']}:${item['service-type']}	
		Append To List  ${CNC_SERVICE_TYPES}	${item['service-type-label']}:${item['service-type']}	
	END	

	Set Suite Variable  ${CNC_SERVICE_TYPES}	

get-service-types
	[Documentation]			Retrieves current running CNC/NSO VPN services
	...						\nSuite Variables: ``CNC_SERVICE_TYPES``
	...						
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_SERVICE_TYPES}=    Create List	
    ${myurl}  Set Variable   /crosswork/cnc/api/v1/serviceTypes
	${payload}	Set Variable	{"transport":true}	

	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--NSO Service Types--\n

	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['serviceTypes']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for NSO Service Types\n
		fail	Test failed.	
	ELSE

		FOR  ${item}  IN  @{json_response['serviceTypes']}
			Set Test Variable    ${MSG}    ${MSG}${item['serviceLayer']}:${item['serviceType']}\n	
			Append To List  ${CNC_SERVICE_TYPES}	${item['serviceLayer']}:${item['serviceType']}	
		END	
	
	END 
	Set Suite Variable  ${CNC_SERVICE_TYPES}	

get-cnc-services
	[Documentation]			Retrieves CNC active VPN service information from /crosswork/cnc/api/v1/services (first 1000)
	...						\nSuite Variables: ``CNC_SERVICES``
	...                       
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_SERVICES}=    Create List	
    ${myurl}  Set Variable   /crosswork/cnc/api/v1/services
	${payload}	Set Variable	{"sortAscending":true,"sortColumn":"serviceName","startRow":0,"endRow":1000,"transport":false,"viewByType":["VPN"],"filterCriteria":{"conditionList":[]}}

	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--VPN Services--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['elements']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for NSO Service Types\n
		fail	Test failed.	
	ELSE	
	
		FOR  ${item}  IN  @{json_response['elements']}
			Set Test Variable    ${MSG}    ${MSG}${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}\n	
			Append To List  ${CNC_SERVICES}	${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}		
		END	
	END
	
	Set Suite Variable  ${CNC_SERVICES}

get-cnc-transport
	[Documentation]			Retrieves CNC active TRANSPORT service information from /crosswork/cnc/api/v1/services (first 1000)
	...						\nSuite Variables: ``CNC_TRANSPORT``
	...                       
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_TRANSPORT}=    Create List	
    ${myurl}  Set Variable   /crosswork/cnc/api/v1/services
	
	${payload}	Set Variable	{"sortAscending":true,"sortColumn":"serviceName","startRow":0,"endRow":1000,"transport":false,"viewByType":["TRANSPORT"],"filterCriteria":{"conditionList":[]}}
	
	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--NSO Transport--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['elements']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for NSO Transport\n
		fail	Test failed.	
	ELSE	
	
		FOR  ${item}  IN  @{json_response['elements']}
			Set Test Variable    ${MSG}    ${MSG}${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}\n	
			Append To List  ${CNC_TRANSPORT}	${item['serviceType']}:${item['serviceName']}:${item['provisioningState']}	
		END	
	END 
	
	Set Suite Variable  ${CNC_TRANSPORT}	

get-syslog-dest
	[Documentation]			Retrieves CNC active SYSLOG configuration information from /crosswork/alarms/v1/syslog-dest/query
	...						\nSuite Variables: ``CNC_SYSLOG_DEST``
	...                       
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_SYSLOG_DEST}=    Create List

    ${myurl}  Set Variable   /crosswork/alarms/v1/syslog-dest/query
	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json	
	${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	
	Set Test Variable    ${MSG}	--NSO Transport--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for Syslog\n
		fail	Test failed.	
	ELSE		
	
		FOR  ${item}  IN  @{json_response['data']}
			Set Test Variable    ${MSG}    ${MSG}\n${item['host']}:${item['port']}:${item['criteria']}
			Append To List  ${CNC_SYSLOG_DEST}	${item['host']}:${item['port']}:${item['criteria']}	
		END	

	END
	Set Suite Variable  ${CNC_SYSLOG_DEST}	


validate-syslog-dest
	[Documentation]			Validates the syslog configuration based on the suite variable of ``CNC_SYSLOG_DEST``
	...                       
	...						\nValidation file(s): cnc-syslog.txt
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
    ${description}  set variable    ${TEST NAME}

	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-syslog.txt
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			log 	comparing ${item} against ${CNC_SYSLOG_DEST}
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_SYSLOG_DEST}  ${item}
			Set Test Variable    ${MSG}    ${MSG}\n${${RESP}[0]X}: [${ENV}]:${item}		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:Syslog entry found in validation list file, but not in system
			Set Tags	${RESP}[0]
		END
	ELSE
		fail 	${FAILX} file [${BASE}${/}ENV${/}${ENV}${/}cnc-syslog.txt] does not exist or invalid
	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} validation(s) failed for SYSLOG configuration	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n	

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

DEPRECATED-get-data-gw
	[Documentation]			DEPRECATED do not use
	...                        
	...						\nValidation file(s): none
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_DATAGW}=    Create List	

	@{FIELDS_DATA}=	Create List	name
	@{FIELDS_CONFIGDATA}=	Create List	version	
	@{FIELDS_OPERDATA}=	Create List

    ${myurl}  Set Variable   /crosswork/dg-manager/v1/dg/query

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	log	${json_response}
	Set Test Variable    ${MSG}	--Data Gateways--\n  
	
	


	Set Suite Variable  ${CNC_DATAGW}	

get-cnc-cdg
	[Documentation]			Retrieves CNC Data gateway key configuration from /crosswork/dg-manager/v1/dg/query
	...						\nSuite Variables: ``CNC_DATAGW`` ``CNC_DATAGW_OPER``
	...                       
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_DATAGW}=    Create List	
	@{CNC_DATAGW_OPER}=    Create List
	
	@{FIELDS_DATA}=	Create List	name
	@{FIELDS_CONFIGDATA}=	Create List	version	adminState	profileType
	@{FIELDS_CONFIGDATA_INTERFACES}=	Create List	name	inetAddr	mask
	@{FIELDS_CONFIGDATA_PROFILE}=	Create List	cpu	memory	nics
	@{FIELDS_OPERDATA}=	Create List	operState
    
	${myurl}  Set Variable   /crosswork/dg-manager/v1/dg/query

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	log	${json_response['data']}
	Set Test Variable    ${MSG}	--Data Gateways--\n   

	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for Data Gateways\n
		fail	Test failed.	
	ELSE		
	
		FOR  ${data}  IN  @{json_response['data']} 
		
			${cdg}	Get Value From Json    ${data}    $.name
			
			FOR  ${item}  IN  @{FIELDS_CONFIGDATA}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data['configData']}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${cdg}:${item}:${values[0]}\n
				Append To List  ${CNC_DATAGW}	${cdg}:${item}:${values[0]}
			END		

			FOR  ${item}  IN  @{FIELDS_CONFIGDATA_PROFILE}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data['configData']['profile']}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${cdg}:${item}:${values[0]}\n
				Append To List  ${CNC_DATAGW}	${cdg}:${item}:${values[0]}
			END	

			FOR  ${item}  IN  @{FIELDS_CONFIGDATA_INTERFACES}
				${search}	Set Variable 	$..${item}
				${values}	Get Value From Json    ${data['configData']['interfaces']}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${cdg}:${item}:${values}\n
				Append To List  ${CNC_DATAGW}	${cdg}:${item}:${values}
			END	
			
			FOR  ${item}  IN  @{FIELDS_OPERDATA}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data['operationalData']}    ${search}
				Append To List  ${CNC_DATAGW_OPER}	${cdg}:${item}:${values[0]}
			END		
		
		END 
	END


	Set Suite Variable  ${CNC_DATAGW}	
	Set Suite Variable  ${CNC_DATAGW_OPER}	

validate-cnc-cdg
	[Documentation]			Validates the data gateway configuration based on the suite variable of ``CNC_DATAGW``
	...                       
	...						\nValidation file(s): cnc-cdg.txt
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-cdg.txt
	
	Set Test Variable    ${MSG}	--Validate CDG--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_DATAGW}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n		
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
	...  fail  ${FAIL_COUNT} validation(s) failed for CDG configuration	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll configuration validated:${FAIL_COUNT} Errors.

validate-cnc-cdg-health
	[Documentation]			Validates the data gateway health on the suite variable of ``CNC_DATAGW_OPER``
	...                       
	...						\nValidation file(s): cnc-cdg-health.txt
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-cdg-health.txt
	
	Set Test Variable    ${MSG}	--Validate CDG Health--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_DATAGW_OPER}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n		
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
	...  fail  ${FAIL_COUNT} validation(s) failed for CDG health	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll configuration validated:${FAIL_COUNT} Errors

get-cnc-cdg-pools
	[Documentation]			Retrieves CNC Data gateway pool key configuration from /crosswork/dg-manager/v2/vdg/query
	...						\nSuite Variables: ``CNC_DATAGW``
	...                       
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_DATAGW_POOL}=    Create List	
	
	@{FIELDS_DATA}=	Create List	name
	@{FIELDS_VIP}=	Create List	inetAddr	inetAddr	mask	gateway
	@{FIELDS_VIP_CDG}=	Create List	cpu	memory	nics
    
	${myurl}  Set Variable   crosswork/dg-manager/v2/vdg/query

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	Set Test Variable    ${MSG}	--Data Gateway Pool(s)--\n   

	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for Data Data Gateway Pool(s)\n
		fail	Test failed.	
	ELSE

		FOR  ${data}  IN  @{json_response['data']} 
		
			${cdg}	Get Value From Json    ${data}    $.name
			
			FOR  ${item}  IN  @{FIELDS_VIP}
				${search}	Set Variable 	$..${item}
				${values}	Get Value From Json    ${data['virtualIPs']}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${cdg}:${item}:${values}\n
				Append To List  ${CNC_DATAGW_POOL}	${cdg}:${item}:${values}
			END		

		END 
	END

	Set Suite Variable  ${CNC_DATAGW_POOL}	

validate-cnc-cdg-pools
	[Documentation]			Validates the data gateway pool configuration based on the suite variable of ``CNC_DATAGW_POOL``
	...                       
	...						\nValidation file(s): cnc-cdg-pools.txt
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-cdg-pools.txt
	
	Set Test Variable    ${MSG}	--Validate CDG Pools--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_DATAGW_POOL}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n		
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
	...  fail   ${FAIL_COUNT} validation(s) failed for CDG pool configuration	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll configuration validated:${FAIL_COUNT} Errors.

DEPRECATED-get-swim-images
	[Documentation]			DEPRECATED do not use
	...						
	...                       
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_SWIM_IMAGES}=    Create List	
    ${myurl}  Set Variable   /crosswork/rs/json/SwimRepositoryRestService/getImagesForRepository/

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=206	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	log	${json_response}
	Set Test Variable    ${MSG}    --CNC Images--\n
	FOR  ${item}  IN  @{json_response['softwareImageListDTO']['items']}
		log	${item}
		
		Set Test Variable    ${MSG}    ${MSG}${item['name']}:${item['version']}:${item['family']}:${item['vendor']}\n	
		Append To List  ${CNC_SWIM_IMAGES}	${item['name']}:${item['version']}:${item['family']}:${item['vendor']}		
	END	

	Set Suite Variable  ${CNC_SWIM_IMAGES}	

get-swim-images
	[Documentation]			Retrieves CNC SWIM/Image info from /crosswork/rs/json/SwimRepositoryRestService/getImagesForRepository
	...						\nSuite Variables: ``CNC_SWIM_IMAGES``
	...                       
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_SWIM_IMAGES}=    Create List	
    ${myurl}  Set Variable   /crosswork/rs/json/SwimRepositoryRestService/getImagesForRepository/

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=206	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json
	
	@{CNC_SWIM_IMAGES}=    Create List
	@{CNC_NODES_HEALTH}=    Create List	
	
	@{FIELDS}=	Create List	name	imageName	version	family	vendor	imagePlatform
	
 	Set Test Variable    ${MSG}	--CNC Images--\n
	
	${count}  Set Variable   ${json_response['softwareImageListDTO']['totalCount']}
	
	IF	${count} > 0
	
		FOR  ${data}  IN  @{json_response['softwareImageListDTO']['items']}
		
			Log	${data}
			
			${key}  Set Variable   ${data['name']}
			
			FOR  ${item}  IN  @{FIELDS}
				${search}	Set Variable 	$.${item}
				
				${values}	Get Value From Json   ${data}    ${search}

				Set Test Variable    ${MSG}    ${MSG}${key}|${item}:${values}\n
				Append To List  ${CNC_SWIM_IMAGES}	${key}|${item}:${values}
				
			END 
			
		END
	ELSE 
		Set Test Variable    ${MSG}    ${MSG}Image Count:${count}
	END 
	
	Set Suite Variable  ${CNC_SWIM_IMAGES}	
	

validate-swim-images
	[Documentation]			Validates the SWIM images based on the suite variable of ``CNC_SWIM_IMAGES``
	...                       
	...						\nValidation file(s): cnc-images.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-images.txt
	
	Set Test Variable    ${MSG}	--Validate CNC images--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_SWIM_IMAGES}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  ${CNC_SWIM_IMAGES}
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
	...  fail  ${FAIL_COUNT} validation(s) failed for SWIM images	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

DEPRECATED-get-cnc-devices
	[Documentation]			Retrieves CNC device information from /crosswork/inventory/v1/nodes/query
	...						\nSuite Variables: ``CNC_DEVICES``
	...                       
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
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
	
	Set Test Variable    ${MSG}    --Devices--\n	
	
	FOR  ${item}  IN  @{json_response['data']}
		log	${item}
	
		Set Test Variable    ${MSG}    ${MSG}\n${item['host_name']}|${item['reachability_state']}:${item['operational_state']}:${item['profile']}:${item['node_ip']}:${item['product_info']['software_type']}:${item['product_info']['software_version']}

		Append To List  ${CNC_DEVICES}	${item['host_name']}|${item['reachability_state']}:${item['operational_state']}:${item['profile']}:${item['node_ip']}:${item['product_info']['software_type']}:${item['product_info']['software_version']}
	END	

	Set Suite Variable  ${CNC_DEVICES}	

get-cnc-devices
	[Documentation]			Retrieves CNC device information from /crosswork/inventory/v1/nodes/query
	...						\nSuite Variables: ``CNC_DEVICES``
	...                       
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_DEVICES}=    Create List
	@{CNC_DEVICES_HEALTH}=    Create List
	@{EXCLUDE_LIST}=    Create List	provider_uuid
	
	@{FIELDS_DATA}=	Create List		profile	dg_name	reachability_check	product_info.software_type	product_info.software_version	product_info.manufacturer	connectivity_info..type	connectivity_info..port	connectivity_info..ipaddrs		
	@{FIELDS_PROVIDER}=	Create List	provider_node_id	provider_name
	#..provider_name	providers_family..provider_node_id	providers_family..provider_name
	@{FIELDS_DATA_HEALTH}=	Create List	admin_state	operational_state	reachability_state	nso_state	errors
	@{FIELDS_EVENTS}=	Create List	alarm_id
	
    ${myurl}  Set Variable   /crosswork/inventory/v1/nodes/query

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	Set Test Variable    ${MSG}    --Devices--\n	

	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Devices failed for Devices(s)\n
		fail	Test failed.	
	ELSE
	
		FOR  ${data}  IN  @{json_response['data']}
		
			${key}	Get Value From Json    ${data}    $.host_name
		
			FOR  ${item}  IN  @{FIELDS_DATA}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${key}:${item}:${values}\n
				Append To List  ${CNC_DEVICES}	${key}:${item}:${values}
			END
			
			@{list}=    Create List
			
			FOR  ${item}  IN  @{FIELDS_PROVIDER}
				${search}	Set Variable 	$.providers_family..${item}
				${values}	Get Value From Json    ${data}    ${search}
				Append To List  ${list}	${item}:${values}

			END			
			${convertListToString}=   Evaluate	":".join(${list})
						
			Append To List  ${CNC_DEVICES}	${key}:${convertListToString}
			Set Test Variable    ${MSG}    ${MSG}${key}:${convertListToString}\n
			
			
			FOR  ${item}  IN  @{FIELDS_DATA_HEALTH}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data}    ${search}
				#Set Test Variable    ${MSG}    ${MSG}${key}:${item}:${values}\n
				Append To List  ${CNC_DEVICES_HEALTH}	${key}:${item}:${values}
			END		

		END	

	END
	
	Set Suite Variable  ${CNC_DEVICES}	
	Set Suite Variable  ${CNC_DEVICES_HEALTH}


get-cnc-devicesx
	[Documentation]			Retrieves CNC device information from /crosswork/inventory/v1/nodes/query
	...						\nSuite Variables: ``CNC_DEVICES``
	...                       
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_DEVICES}=    Create List
	@{CNC_DEVICES_HEALTH}=    Create List
	
	@{FIELDS_DATA}=	Create List		profile	dg_name	reachability_check	product_info.software_type	product_info.software_version	product_info.manufacturer	connectivity_info..type	connectivity_info..port	connectivity_info..ipaddrs	providers_family..provider_name
	@{FIELDS_DATA_HEALTH}=	Create List	admin_state	operational_state	reachability_state	nso_state	errors
	@{FIELDS_EVENTS}=	Create List	alarm_id
	
    ${myurl}  Set Variable   /crosswork/inventory/v1/nodes/query

	${payload}	Set Variable	{}
	${payload_json}	evaluate  json.loads($payload)    json

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200	json=${payload_json}

    ${json_response}    evaluate  json.loads($response.text)    json

	Set Test Variable    ${MSG}    --Devices--\n	

	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for Data Data Gateway Pool(s)\n
		fail	Test failed.	
	ELSE
	
		FOR  ${data}  IN  @{json_response['data']}
		
			Log	${data}
			
			${key}	Get Value From Json    ${data}    $.host_name
			@{TEMP}=    Create List
		
			FOR  ${item}  IN  @{FIELDS_DATA}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data}    ${search}
				#Set Test Variable    ${MSG}    ${MSG}${key}:${item}:${values}\n
				#Append To List  ${CNC_DEVICES}	${key}:${item}:${values}
				Append To List  ${TEMP}	${key}|${item}:${values}
			END
			
			FOR  ${item}  IN  @{FIELDS_DATA_HEALTH}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data}    ${search}
				#Set Test Variable    ${MSG}    ${MSG}${key}:${item}:${values}\n
				Append To List  ${CNC_DEVICES_HEALTH}	${key}:${item}:${values}
			END		
		Log list 	${TEMP}
		Append To List  ${CNC_DEVICES}	${TEMP}
		Log list	${CNC_DEVICES}

		END	

	END
	Log list 	${CNC_DEVICES}


	Set Suite Variable  ${CNC_DEVICES}	
	Set Suite Variable  ${CNC_DEVICES_HEALTH}	
	Set Test Variable    ${MSG}    ${MSG}${CNC_DEVICES}\n

	
validate-cnc-devices
	[Documentation]			Validates the CNC services/applications based on the suite variable of ``CNC_DEVICES``
	...                       
	...						\nValidation file(s): cnc-devices.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-devices.txt
	
	Set Test Variable    ${MSG}	--Validate CNC Devices--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_DEVICES}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n		
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

	END
	
	FOR  ${item}  IN  @{CNC_DEVICES}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Appears to be a new entry not in the validation list.\n
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END		

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} validation(s) failed for Device configuration	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll configuration validated:${FAIL_COUNT} Errors.

validate-cnc-device-health
	[Documentation]			Validates the CNC services/applications based on the suite variable of ``CNC_DEVICES_HEALTH``
	...                       
	...						\nValidation file(s): cnc-device-health.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	#${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-device-health.txt
	
	@{VALIDATE_LIST}=    Create List	DOWN	UNREACHABLE	ERROR	DEGRADED	errors
	#@{VALIDATE_LIST}=    Create List	errors	

	
	Set Test Variable    ${MSG}	--Validate CNC Device Health--\n
	
	
	FOR  ${iter}  IN  @{CNC_DEVICES_HEALTH}
		Log 	${iter}
		
		FOR  ${validate}  IN  @{VALIDATE_LIST}

			${RESP}	Run Keyword and Ignore Error	Should Contain	${iter}	${validate}
			
			IF  "${RESP}[0]" == "PASS"	
				Log	Checking if errors:[] is equal to ${iter}
				
				${equal}  Run Keyword And Ignore Error	Should Not Contain	${iter}	errors:[]	
				
				IF  "${equal}[0]" == "PASS"	
					Set Test Variable    ${MSG}    ${MSG}${FAILX}: [${ENV}]:${iter}\n	
					Append To List  ${FAIL}  ---					
					Set Tags	${RESP}[0]				
				END

			END
		END 
	END
	
	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} Failures were seen on one or more devices.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n	
	
	Set Test Variable    ${MSG}    ${MSG}\nNo device errors detect. Errors:${FAIL_COUNT}

validate-device-alarms
	[Documentation]			Checks and reports on the presence of device level alarms captured during ``get-device-alarms`` and stored in  of ``CNC_DEVICE_ALARMS``
	...                       
	...						\nValidation file(s):none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-05
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	@{VALIDATE_LIST}=    Create List	DOWN	UNREACHABLE	ERROR	DEGRADED	errors
	#@{VALIDATE_LIST}=    Create List	errors	
	
	Set Test Variable    ${MSG}	--Reported Device Alarms--\n
	
	${ALARM_COUNT}=  Get Length  ${CNC_DEVICE_ALARMS}
	
	#Run Keyword If  ${ALARM_COUNT} == 0 
	#...  pass  No device alarms detected.	

	FOR  ${item}  IN  @{CNC_DEVICE_ALARMS}
		Log	${item}

		Set Test Variable    ${MSG}    ${MSG}${FAILX}: [${ENV}]:${item}\n	
		Append To List  ${FAIL}  FAIL
		Set Tags	FAIL
	END 

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} Failures were seen on one or more devices.	

	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n
	
	Set Test Variable    ${MSG}    ${MSG}\nNo device errors detect. Errors:${FAIL_COUNT}

validate-nso-service-types
	[Documentation]			Validates the running NSO service types based on the suite variable of ``CNC_SERVICE_TYPES``
	...                       
	...						\nValidation file(s): cnc-nso-service-types.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-nso-service-types.txt
	
	Set Test Variable    ${MSG}	--Validate CNC NSO Service Types--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_SERVICE_TYPES}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n	
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END

		FOR  ${item}  IN  @{CNC_SERVICE_TYPES}
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
			IF  "${RESP}[0]" == "FAIL"	
				Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Appears to be a new entry not in the validation list.\n
				Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
			END
		END	
	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} validation(s) failed for NSO Service types
		
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll service types validated:${FAIL_COUNT} Errors.

validate-cnc-services
	[Documentation]			Validates the running NSO service types based on the suite variable of ``CNC_SERVICES``
	...                       
	...						\nValidation file(s): cnc-services.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-services.txt
	
	Set Test Variable    ${MSG}	--Validate CNC Services--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_SERVICES}  ${item}
			Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n	
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
	...  fail  ${FAIL_COUNT} validation(s) failed for CNC Services	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

validate-cnc-transport
	[Documentation]			Validates the running NSO transport services based on the suite variable of ``CNC_TRANSPORT``
	...                       
	...						\nValidation file(s): cnc-transport.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-transport.txt
	
	Set Test Variable    ${MSG}	--Validate CNC Transport--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_TRANSPORT}  ${item}
			Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n	
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
	...  fail  ${FAIL_COUNT} validation(s) failed for CNC Transport services
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll tests passed. Failures:${FAIL_COUNT}

get-device-alerts
	[Documentation]			Retrieves KPI alerts associated with devices and KPIs. Limited to first 100 devices.
	...                       
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{FAIL_DEVICE}=    Create List	
	@{FAIL_KPI}=    Create List	
	
    ${description}  set variable    ${TEST NAME}
	
    ${myurl}  Set Variable   /crosswork/hi/v1/alerts/device/devices
	${payload}	Set Variable	{"time_ago":"0m","offset":"0","time_interval":"1h","levels":["CRITICAL","MAJOR","WARNING","MINOR","INFO"],"limit":"100","top_devices":true}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${alerts}    evaluate  json.loads($response.text)    json
	
	Set Test Variable    ${MSG}	--CNC Device Alerts--\n

	${RESP}  Run Keyword And Ignore Error	Get Length	${alerts} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Device Alerts\n
		fail	Test failed.	
	ELSE
		
		FOR  ${item}  IN  @{alerts['device_alerts']}
			Log	${item['device_id']}
			Set Test Variable    ${MSG}    ${MSG}Device:${item['device_id']}:${item['impact_score']}\n	
			Append To List  ${FAIL_DEVICE}  FAIL_DEVICE		
		END	
		FOR  ${item}  IN  @{alerts['kpi_alerts']}
			Log	${item['device_id']}
			Set Test Variable    ${MSG}    ${MSG}KPI:${item['device_id']}:${item['impact_score']}\n		
			Append To List  ${FAIL_KPI}  FAIL_KPI
		END		
	END
	
get-cnc-credentials
	[Documentation]			Retrieves CNC Credentials
	...						\nSuite Variables: ``CNC_CREDENTIALS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_CREDENTIALS}=    Create List	
	
    ${myurl}  Set Variable   /crosswork/inventory/v1/credentials/query
	${payload}	Set Variable	{"limit":100,"next_from":"0","filter":{}}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${credentials}    evaluate  json.loads($response.text)    json
	
	Set Test Variable    ${MSG}    --CNC Credentials--\n

	${RESP}  Run Keyword And Ignore Error	Get Length	${credentials['data']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Credentials\n
		fail	Test failed.	
	ELSE
	
		FOR  ${item}  IN  @{credentials['data']}
			Log	${item}
			Append To List  ${CNC_CREDENTIALS}	${item['profile']}
			
			FOR  ${user}  IN  @{item['user_pass']}
				Set Test Variable    ${MSG}    ${MSG}${item['profile']}|${user['user_name']}:${user['type']}\n
				Append To List  ${CNC_CREDENTIALS}	${item['profile']}|${user['user_name']}:${user['type']}
			END
			
			#Set Test Variable    ${MSG}    ${MSG}\n${item['profile']}:${item['user_pass']}:${item['type']}			

		END	
	END	
		
	Set Suite Variable  ${CNC_CREDENTIALS}


get-cnc-credentials-v2
	[Documentation]			Retrieves CNC Credentials
	...						\nSuite Variables: ``CNC_CREDENTIALS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_CREDENTIALS}=    Create List	
	
	@{FIELDS_DATA}=	Create List	user_name	type
	
    ${myurl}  Set Variable   /crosswork/inventory/v1/credentials/query
	${payload}	Set Variable	{"limit":100,"next_from":"0","filter":{}}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	
	Set Test Variable    ${MSG}    --CNC Credentials--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for credentials\n
		fail	Test failed.
	ELSE 
	
		FOR  ${data}  IN  @{json_response['data']} 
		
			${key}  Set Variable   ${data['profile']}

			FOR  ${item}  IN  @{FIELDS_DATA}
				${search}	Set Variable 	$..${item}
				${values}	Get Value From Json    ${data}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${key}|${item} : ${values}\n
				Append To List  ${CNC_CREDENTIALS}	${key}|${item} : ${values}
			END		
			
		END 	

	END 

	Set Suite Variable  ${CNC_CREDENTIALS}

DEPRECATED-get-cnc-providers
	[Documentation]			Retrieves CNC Providers (first 100)
	...						\nSuite Variables: ``CNC_PROVIDERS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_PROVIDERS}=    Create List	
	
    ${myurl}  Set Variable   /crosswork/inventory/v1/providers/query
	${payload}	Set Variable	{"limit":100,"next_from":"0","filter":{}}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${providers}    evaluate  json.loads($response.text)    json
	
	Set Test Variable    ${MSG}	--Providers--\n
	
	FOR  ${item}  IN  @{providers['data']}
		Log	${item}
		
		FOR  ${connectivity}  IN  ${item['connectivity_info']}

		#Set Test Variable    ${MSG}    ${MSG}\n${item['name']}|${item['reachability_state']}
			Set Test Variable    ${MSG}    ${MSG}${item['name']}|${item['reachability_state']}:${connectivity}\n
			Append To List  ${CNC_PROVIDERS}	${item['name']}|${item['reachability_state']}:${connectivity}		

		END

	END	
	
	Set Suite Variable  ${CNC_PROVIDERS}	

get-cnc-providers
	[Documentation]			Retrieves CNC Providers (first 100)
	...						\nSuite Variables: ``CNC_PROVIDERS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	${myurl}  Set Variable   /crosswork/inventory/v1/providers/query
	${payload}	Set Variable	{"limit":100,"next_from":"0","filter":{}}

	${json_payload}	evaluate  json.loads($payload)    json
	
	@{CNC_PROVIDERS}=    Create List
	@{CNC_NODES_HEALTH}=    Create List	
	
	@{FIELDS}=	Create List	profile	connectivity_info..port	connectivity_info..timeout	connectivity_info..type	connectivity_info..ipaddrs
	
    ${description}  set variable    ${TEST NAME}

    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Providers--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']}
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Providers\n
		fail	Test failed.	
	ELSE
	
		FOR  ${data}  IN  @{json_response['data']}
		
			Log	${data}
			
			${key}  Set Variable   ${data['name']}
			
			FOR  ${item}  IN  @{FIELDS}
				${search}	Set Variable 	$.${item}
				
				${values}	Get Value From Json   ${data}    ${search}

				Set Test Variable    ${MSG}    ${MSG}${key}|${item}:${values}\n
				Append To List  ${CNC_PROVIDERS}	${key}|${item}:${values}
				
			END 
			
		END
	END
	Set Suite Variable  ${CNC_PROVIDERS}	


DEPRECATED-get-system-alarms
	[Documentation]			DEPRECATED do not use
	...						
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	
	@{FIELDS_OPERDATA}=	Create List	State	
	@{FIELDS_EVENTS}=	Create List	EventCategory	origin_app_id
	
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

get-system-alarms
	[Documentation]			Retrieves Open/active system level alarms (first 10)
	...						\nSuite Variables: ``CNC_SYSALARMS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
	[arguments]	${numalarms}=${numalarms}
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
    ${description}  set variable    ${TEST NAME}
	
	@{CNC_SYSALARMS}=    Create List
	
	@{FIELDS_DATA}=	Create List		Description		events_count

	@{FIELDS_EVENTS}=	Create List	alarm_id
	
    ${myurl}  Set Variable   /crosswork/alarms/v1/query
	${payload}	Set Variable	{"openAlarmsOnly":false,"criteria":"select * from alarm limit ${numalarms} page 0 where (state = 5 or state = 6)"}
	${json_payload}	evaluate  json.loads($payload)    json
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	json=${json_payload}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC System Alarms limit:(${numalarms})--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	{json_response['alarms']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC System Alarms\n
		fail	Test failed.	
	ELSE	
	
		FOR  ${data}  IN  @{json_response['alarms']} 

			${key}	Get Value From Json    ${data}    $.State
			${key3}	Get Value From Json    ${data}    $.AlarmCategory	
			${key2}	Get Value From Json    ${data}    $.Created			
			
			Set Test Variable    ${MSG}    ${MSG}\n--- Alarm | ${key}[0] | ${key3}[0] | ${key2}[0] ---\n
			
			FOR  ${item}  IN  @{FIELDS_DATA}
				${search}	Set Variable 	$.${item}
				${values}	Get Value From Json    ${data}    ${search}
				Set Test Variable    ${MSG}    ${MSG}${item} : ${values}\n
				Append To List  ${CNC_SYSALARMS}	Alarms
			END		
			
		END 
	END 
	Set Suite Variable  ${CNC_SYSALARMS}


get-device-alarms
	[Documentation]			Retrieves Open/active device level level alarms (all)
	...						\nSuite Variables: ``CNC_DEVICE_ALARMS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   status
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	set to dictionary  ${headers}  Range=items=0-99
	
    ${description}  set variable    ${TEST NAME}
	@{CNC_DEVICE_ALARMS}=    Create List	
	
    ${myurl}  Set Variable   /crosswork/platform/alarms/v1/alarms/?type=device&_COND=and&severity=Critical,Major&_SORT=lastModifiedTimestamp.DESC
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	
	Should Be True  '${response.status_code}'=='200' or '${response.status_code}'=='206' 
    
	${alarms}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--Device Alarms--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	{json_response['alarms']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for Device Alarms\n
		fail	Test failed.	
	ELSE	

		FOR  ${item}  IN  @{alarms}
			Log	${item}
			Set Test Variable    ${MSG}    ${MSG}${item['displayName']}|${item['severity']}:${item['eventType']}:${item['source']}:${item['description']}\n
			Append To List  ${CNC_DEVICE_ALARMS}	${item['displayName']}|${item['severity']}:${item['eventType']}:${item['source']}:${item['description']}
		END	
	END 
	
	Set Suite Variable  ${CNC_DEVICE_ALARMS}

get-kpis
	[Documentation]			Retrieve and reports on CAHI defined alerts (KPIs)
	...						\nSuite Variables: ``CNC_KPI`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   /crosswork/hi/v1/kpis
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CNC_KPI}=    Create List	
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	
	${RESP}  Run Keyword And Ignore Error	Get Length	{json_response['kpis']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for KPIs\n
		fail	Test failed.	
	ELSE		
	
		FOR  ${item}  IN  @{json_response['kpis']['kpi']}
			#Set Test Variable    ${MSG}    ${MSG}\n[${item['category']}] ${item['kpi_name']}:${item['sensor_type']} 
			Append To List  ${CNC_KPI}	[${item['category']}] ${item['kpi_name']}:${item['sensor_type']} 
		END	
	END 
	
	${NUM_KPI}	Get Length	${CNC_KPI}
	Set Test Variable    ${MSG}    ${MSG}# KPIs: ${NUM_KPI}

	Set Suite Variable  ${CNC_KPI}	


get-cnc-slo
	[Documentation]			Retrieves CNC Providers (first 100)
	...						\nSuite Variables: ``CNC_PROVIDERS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	${myurl}  Set Variable   /crosswork/cnc/api/v1/getTemplatesByName
	
	
	@{XX}=    Create List
	@{CNC_NODES_HEALTH}=    Create List	
	
	@{FIELDS}=	Create List	policyType	L2-input-policy	L3-input-policy	L2-output-policy	L3-output-policy	forward-plane-policy	
	
    ${description}  set variable    ${TEST NAME}

    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Templates--\n
	
	${RESP}  Run Keyword And Ignore Error	Get Length	${json_response['data']}
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Templates\n
		fail	Test failed.	
	ELSE
	
		FOR  ${data}  IN  @{json_response['data']}
		
			Log	${data}
			
			${key}  Set Variable   ${data['id']}
			@{TEMP}=    Create List
			
			FOR  ${item}  IN  @{FIELDS}
				${search}	Set Variable 	$.${item}
				
				${values}	Get Value From Json   ${data}    ${search}
				Append To List  ${TEMP}	${item}:${values}
		
				
			END 
			
			Log list	${TEMP}
			
			#Set Test Variable    ${MSG}    ${MSG}${TEMP}\n
			Append To List  ${XX}	@{TEMP}
		END
	END
	Log list	${XX}
	Set Test Variable	${XX}
	Set Suite Variable  ${XX}	


get-application-versions
	[Documentation]			Retrieves the CNC application versions and stores result in suit variabe ``CNC_APP_VERSIONS``
	...						\nSuite Variables: ``CNC_APP_VERSIONS`` 
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-03
	
    ${myurl}  Set Variable   /crosswork/platform/v2/capp/applicationsummary/query
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CNC_APP_VERSIONS}=    Create List	
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   POST On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Application Versions--
	
	${RESP}  Run Keyword And Ignore Error	Get Length	{json_response['application_summary_list']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Application Versions\n
		fail	Test failed.	
	ELSE		
	
		FOR  ${item}  IN  @{json_response['application_summary_list']}
			Set Test Variable    ${MSG}    ${MSG}\n${item['application_data']['application_id']}:${item['application_data']['version']}	
			Append To List  ${CNC_APP_VERSIONS}	${item['application_data']['application_id']}:${item['application_data']['version']}		
		END	
	END 
	
	Set Suite Variable  ${CNC_APP_VERSIONS}	


validate-cnc-app-versions
	[Documentation]			Validates the CNC application versions based on the suite variable of ``CNC_APP_VERSIONS``
	...						
	...						\nValidation file(s): cnc-apps.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-apps.txt
	
	Set Test Variable    ${MSG}	--Validate CNC app versions--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_APP_VERSIONS}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n	
			Append To List  ${${RESP}[0]}  ${RESP}[0]:${item}:App found in validation list, but not in system
			Set Tags	${RESP}[0]
		END
		
	FOR  ${item}  IN  @{CNC_APP_VERSIONS}
		${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${appsVALID}  ${item}
		IF  "${RESP}[0]" == "FAIL"	
			Set Test Variable    ${MSG}    ${MSG}\nWARN: ${item} Appears to be a new entry not in the validation list.\n
			Append To List  ${${RESP}[0]-REV}  ${RESP}[0]:${item}
		END
	END		

	END

	${FAIL_COUNT}=  Get Length  ${FAIL}
	${FAIL_COUNT_REV}=  Get Length  ${FAIL-REV}
	
	Log List  ${PASS}
	Log List  ${FAIL}	
	Log List  ${FAIL-REV}
	
	Run Keyword If  ${FAIL_COUNT} > 0  
	...  fail  ${FAIL_COUNT} validation(s) failed for CNC App versions.
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll versions validated:${FAIL_COUNT} Errors.

get-application-health
	[Documentation]			Retrieves health info from the CNC cluster api (/crosswork/platform/v2/cluster/app/health/list). Creates 2 variables - one for healty applications, one for degraded.
	...						\nSuite Variables: ``CNC_APP_HEALTHY`` and ``CNC_APP_DEGRADED``
	...
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02

    ${myurl}  Set Variable   /crosswork/platform/v2/cluster/app/health/list
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/xml
	set to dictionary  ${headers}  Authorization=Bearer ${token}
	
	@{CNC_APP_HEALTHY}=    Create List	
	@{CNC_APP_DEGRADED}=    Create List	
	
    ${description}  set variable    ${TEST NAME}
	
    ${response}   GET On Session  cw  ${myurl}  headers=${headers}	expected_status=200

    ${json_response}    evaluate  json.loads($response.text)    json
	Set Test Variable    ${MSG}	--CNC Application Health--\n

	${RESP}  Run Keyword And Ignore Error	Get Length	{json_response['app_health_summary']} 
	IF  "${RESP}[0]" == "FAIL"
		Set Test Variable    ${MSG}    ${MSG}Data Collection failed for CNC Application Health\n
		fail	Test failed.	
	ELSE

		FOR  ${item}  IN  @{json_response['app_health_summary']}
			
			${equal}  Run Keyword And Ignore Error	Should Be Equal As Strings	${item['health_summary']['state']}	Healthy
			
			IF	"${equal}[0]" == "PASS"
				Append To List  ${CNC_APP_HEALTHY}	${item['health_summary']['obj_name']}
				Set Test Variable    ${MSG}    ${MSG}${item['health_summary']['obj_name']}:Healthy\n
				
			ELSE 
				Set Test Variable    ${MSG}    ${MSG}${item['health_summary']['obj_name']}:Degraded\n
				Append To List  ${CNC_APP_DEGRADED}	${item['health_summary']['obj_name']}		
			END
		
			#Set Test Variable    ${MSG}    ${MSG}\n${item['application_data']['application_id']}:${item['application_data']['version']}	
			#Append To List  ${CNC_APP_VERSIONS}	${item['application_data']['application_id']}:${item['application_data']['version']}		
		END	
	END 
	
	Set Suite Variable  ${CNC_APP_DEGRADED}	
	Set Suite Variable  ${CNC_APP_HEALTHY}	

validate-cnc-application-health
	[Documentation]			Validates the application health based on the suite variable of ``CNC_APP_DEGRADED``
	...                       
	...						\nExternal files: none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${FAIL_COUNT}=  Get Length  ${CNC_APP_DEGRADED}
	
	Set Test Variable    ${MSG}	--Validate CNC app health--\n

	FOR  ${item}  IN  @{CNC_APP_DEGRADED}
		Set Test Variable    ${MSG}    ${MSG}FAIL: [${ENV}]:${item} is Degraded\n
		Set Tags	FAIL		
	END

	Run Keyword If  ${FAIL_COUNT} > 0 
	...  fail   ${FAIL_COUNT} applications degraded. 
	
	#FOR  ${item}  IN  @{CNC_APP_HEALTHY}
	#	Set Test Variable    ${MSG}    ${MSG}PASS: [${ENV}]:${item} is Healthy\n
	#	Set Tags	PASS
	#END

	Run Keyword If  ${FAIL_COUNT} == 0 
	...  pass execution   ${FAIL_COUNT} applications were listed as degraded.

validate-cnc-credentials
	[Documentation]			Validates the application health based on the suite variable of ``CNC_CREDENTIALS``
	...						
	...						\nValidation file(s): cnc-credentials.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-credentials.txt
	
	Set Test Variable    ${MSG}	--Validate Credentials--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_CREDENTIALS}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n
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
	...  fail  ${FAIL_COUNT} validation(s) failed for CNC Credential configuration.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll credentials validated. Failures:${FAIL_COUNT}

validate-cnc-providers
	[Documentation]			Validates the CNC Providers (NSO,CDG etc) based on the suite variable of ``CNC_PROVIDERS``
	...						
	...						\nValidation file(s): cnc-providers.txt
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	@{FAIL}=    Create List	
	@{PASS}=    Create List	
	@{PASS-REV}=    Create List		
	@{FAIL-REV}=    Create List	

	${RESP}  Run Keyword And Ignore Error	Load Data from File  ${BASE}${/}ENV${/}${ENV}${/}cnc-providers.txt
	
	Set Test Variable    ${MSG}	--Validate CNC providers--\n
	
	IF	"${RESP}[0]" == "PASS"
		${appsVALID}	Set Variable	${RESP}[1]
		@{appsVALID}=    Split to lines  ${appsVALID}

		FOR  ${item}  IN  @{appsVALID}
			# Positive
			${RESP}=  Run Keyword And Ignore Error  List Should Contain Value  ${CNC_PROVIDERS}  ${item}
			Run Keyword If	"${RESP}[0]"=="FAIL"	Set Test Variable    ${MSG}    ${MSG}${${RESP}[0]X}: [${ENV}]:${item}\n
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
	...  fail  ${FAIL_COUNT} provider(s) entries failed validation.	
	
	Run Keyword If  ${FAIL_COUNT_REV} > 0  
	...  pass execution  Appears to be a new entry not in the validation list.\n

	Set Test Variable    ${MSG}    ${MSG}\nAll provider entries validated. Failures:${FAIL_COUNT}



Logon to CNC
	[Documentation]			Retrieves the CNC Authentication token
	...						
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
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
	
	${myTGT}    	Set Variable	${resp.text}

	${resp2}	RequestsLibrary.POST ON Session	cw	${serverURL}${tgt}/${resp.text}	headers=${headers}  expected_status=200	verify=${False}	data=${payload}
	
	${token}  set variable  ${resp2.text}
	set suite variable  ${token}
	set suite variable  ${myTGT}
	log	${myTGT}

	Set Test Variable    ${MSG}    ${MSG}HOST: ${serverURL}
	Set Test Variable    ${MSG}    ${MSG}\nUSER: ${data["auth"]["username"]}	
	

Delete CNC Token
	[Documentation]			Dispose of CNC token
	...						
	...						\nValidation file(s): none
	...                     \nAuthor: Simon Price
	...                     \nUpdate: 2024-12-02
	
	Log Variables  level=TRACE	
	
    ${myurl}  Set Variable   /crosswork/sso/v1/tickets/${myTGT}
	${headers}  Create Dictionary
	set to dictionary  ${headers}  Content-type=application/json
	set to dictionary  ${headers}  Authorization=Bearer ${token}

    ${response}   DELETE On Session  cw  ${myurl}  headers=${headers}	expected_status=200


Suite Setup	
	[Tags]  setup
	[Documentation]  Load environments and get current time stamp
	Create Hosts
	Get Current DTTM

Suite Teardown

	[Tags]  teardown
	[Documentation]  Dispose of Sessions
	
	Delete CNC Token
	Delete All sessions
	


