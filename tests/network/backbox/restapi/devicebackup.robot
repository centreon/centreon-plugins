*** Settings ***
Documentation       Check a device backup status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}backbox.json
${HOSTNAME}             127.0.0.1
${APIPORT}              3000

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::backbox::restapi::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token=token
...                 --mode=device-backup

*** Test Cases ***
Device backup ${tc}
    [Documentation]    Check a device backup status
    [Tags]    network    backbox    restapi    backup
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:         tc    extraoptions                                                                               expected_result    --
            ...       1     ${EMPTY}                                                                                   UNKNOWN: Need to specify --device-id or --device-name option.
            ...       2    --device-name="Juniper SRX"                                                                 OK: Device [id: 4] [name: Juniper SRX] [status: SUCCESS] [status reason: ]
            ...       3    --device-id=4                                                                               OK: Device [id: 4] [name: ] [status: SUCCESS] [status reason: ]
            ...       4    --device-name="Juniper SRX" --device-id=4                                                   OK: Device [id: 4] [name: Juniper SRX] [status: SUCCESS] [status reason: ]
            ...       5    --device-name="Cisco C8000"                                                                 CRITICAL: Device [id: 1] [name: Cisco C8000] [status: FAILURE] [status reason: The failed expected result was found: (No route to host)]
            ...       6    --device-id=1                                                                               CRITICAL: Device [id: 1] [name: ] [status: FAILURE] [status reason: The failed expected result was found: (No route to host)]
            ...       7    --device-name="Fortinet Fortigate"                                                          WARNING: Device [id: 3] [name: Fortinet Fortigate] [status: SUSPECT] [status reason: Unknown status]
            ...       8    --device-id=3                                                                               WARNING: Device [id: 3] [name: ] [status: SUSPECT] [status reason: Unknown status]
            ...       9    --device-id=3 --critical-status='\\\%{status} =~ /FAILURE|SUSPECT/i'                        CRITICAL: Device [id: 3] [name: ] [status: SUSPECT] [status reason: Unknown status]
            ...       10   --device-id=1 --warning-status='\\\%{status} =~ /FAILURE|SUSPECT/i' --critical-status=''    WARNING: Device [id: 1] [name: ] [status: FAILURE] [status reason: The failed expected result was found: (No route to host)]
            ...       11   --device-id=3 --critical-status='\\\%{status_reason} =~ /unknown/i'                         CRITICAL: Device [id: 3] [name: ] [status: SUSPECT] [status reason: Unknown status]
            ...       12   --device-name="Fortinet Fortigate" --critical-status='\\\%{device_name} =~ /Fortinet/i'     CRITICAL: Device [id: 3] [name: Fortinet Fortigate] [status: SUSPECT] [status reason: Unknown status]
            ...       13   --device-name="Fortinet Fortigate" --critical-status='\\\%{device_id} == 3'                 CRITICAL: Device [id: 3] [name: Fortinet Fortigate] [status: SUSPECT] [status reason: Unknown status]
