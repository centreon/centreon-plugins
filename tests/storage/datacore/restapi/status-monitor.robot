*** Settings ***
Documentation       datacore rest api plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}storage-datacore-api.json

${CMD}              ${CENTREON_PLUGINS} --plugin=storage::datacore::restapi::plugin --password=pass --username=user --port=${APIPORT} --hostname=${HOSTNAME} --proto=http


*** Test Cases ***
Datacore check status monitor ${tc}
    [Documentation]    Check Datacore pool usage
    [Tags]    storage    api
    ${command}    Catenate
    ...    ${CMD} 
    ...    --mode=status-monitor
    ...    --statefile-dir=/dev/shm/
    
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc      expected_result   --
        ...      1       CRITICAL: 'State of HostVM2' status : 'Critical', message is 'Connected'
