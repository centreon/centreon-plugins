*** Settings ***
Documentation       VeloCloud REST API Edge Status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}velocloud.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=cloud::vmware::velocloud::restapi::plugin
...                 --mode edge-status
...                 --hostname=${HOSTNAME}
...                 --username=XloginX
...                 --password=XpasswordX
...                 --proto=http
...                 --port=${APIPORT}
...                 --custommode=api
...                 --statefile-dir=/dev/shm/

*** Test Cases ***
Edge Status ${tc}
    [Tags]    cloud     api    vmware
    ${command}    Catenate    ${CMD}    ${extraoptions}    
    ${output}    Run    ${command}

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True


    Examples:    tc        extraoptions                  expected_result   --
        ...      1        ${EMPTY}                       CRITICAL: Edge 'MYEDGE#02' State is 'OFFLINE', Service State is 'IN_SERVICE', HA State is 'READY', Activation State is 'ACTIVATED'
        ...      2        --critical-status=''           OK: All edges status are ok