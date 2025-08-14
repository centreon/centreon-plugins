*** Settings ***
Documentation       Check the LatenceTech discovery mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::monitoring::latencetech::restapi::plugin
...                 --custommode=api
...                 --mode=discovery
...                 --hostname=${HOSTNAME}
...                 --api-key=key
...                 --port=${APIPORT}
...                 --proto=http

*** Test Cases ***
Discovery ${tc}
    [Documentation]    Check LatenceTech discovery
    [Tags]    apps    monitoring    latencetech    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --customer-id=0
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Json    ${command}    ${expected_result}

    Examples:    tc    extraoptions    expected_result    --
    ...          1     ${EMPTY}
    ...          {"duration":3716,"start_time":1753278888,"discovered_items":3,"results":[{"gpsPosition":"48.864716,2.349014","networkType":"Outscale","hardware":"Not-Applicable","networkName":"OutScale-Network","id":"0","details":"Generic QoSAgent preinstalled with OMI","name":"GenericQoSAgent"},{"gpsPosition":",undefined","networkType":"Azure Server Network","id":"2","details":"Azure Agent used for demonstration purposes","name":"Germany WEST","hardware":"Azure Server","networkName":"Azure Net 2"},{"details":"Uses india beacon reflector","id":"3","name":"South Central US","hardware":"Azure Server","networkName":"","networkType":"Azure Server Network","gpsPosition":",undefined"}],"end_time":1753282604}
