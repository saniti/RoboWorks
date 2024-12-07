*** Settings ***

Documentation           This Robot Framework resource file contains common keywords
...                     for driving CNC Test cases via API.
...
...                     Author: Simon Price 

*** keywords ***

Create Hosts
	[Documentation]			Creates the CNC host and credential definitions
	...                       
	...						\nValidation file(s): n/a
	...						\nAuthor: Simon Price
	...						\nUpdate: 2024-12-02
	
	${CW_ENDPOINTS}    Create Dictionary
	
	# Accounts and passwords
	
	${admin_default}  Set Variable	{"username":"admin","password":"mypassword"}
	${admin_default_2}  Set Variable	{"username":"admin","password":"mypassword"}


	# Hosts and ports with references to account details above
	
	set to dictionary  ${CW_ENDPOINTS}  mycnclablocal  {"host":"192.168.254.233","protocol":"https","port":"30605","auth":${admin_default}}
	set to dictionary  ${CW_ENDPOINTS}  dclouddemo  {"host":"198.18.134.219","protocol":"https","port":"30603","auth":${admin_default_2}}

	

	
	Set Suite Variable  ${CW_ENDPOINTS}
	
	