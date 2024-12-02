*** Settings ***

Documentation           This Robot Framework resource file contains common keywords
...                     for driving CNC Test cases via API.
...
...                     Author: Simon Price

*** keywords ***

Create Hosts
	${CW_ENDPOINTS}    Create Dictionary
	
	# Accounts and passwords
	
	${admin_default}  Set Variable	{"username":"admin","password":"cRo55work!"}
	${admin_default_2}  Set Variable	{"username":"admin","password":"mypassword"}	


	# Hosts and ports with references to account details above
	
	set to dictionary  ${CW_ENDPOINTS}  dcloud-demo  {"host":"198.18.134.219","protocol":"https","port":"30603","auth":${admin_default}}
	set to dictionary  ${CW_ENDPOINTS}  mycnclablocal  {"host":"192.168.254.233","protocol":"https","port":"30605","auth":${admin_default_2}}	


	Set Suite Variable  ${CW_ENDPOINTS}
	
	