*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=eth-ports
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
eth-ports ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options             expected_result    --
            ...       1       ${EMPTY}                  OK: Ethernet ports: 6 detected, 2 active, 6 role-capable, 0 IP configured - All Ethernet ports in service are active | 'ethports.detected.count'=6;;;0; 'ethports.active.count'=2;;;0; 'ethports.withrole.count'=6;;;0; 'ethports.ip.configured.count'=0;;;0;
            ...       2       --add-unused              OK: Ethernet ports: 6 detected, 2 active, 6 role-capable, 0 IP configured - All Ethernet ports in service are active | 'ethports.detected.count'=6;;;0; 'ethports.active.count'=2;;;0; 'ethports.withrole.count'=6;;;0; 'ethports.ip.configured.count'=0;;;0;
            ...       3       --critical-active=1       CRITICAL: Ethernet ports: 2 active | 'ethports.detected.count'=6;;;0; 'ethports.active.count'=2;;0:1;0; 'ethports.withrole.count'=6;;;0; 'ethports.ip.configured.count'=0;;;0;
            ...       4       --filter-name='^node1'    OK: Ethernet ports: 3 detected, 1 active, 3 role-capable, 0 IP configured - Port 'node1-1' link active, speed 1Gb/s, roles: management | 'ethports.detected.count'=3;;;0; 'ethports.active.count'=1;;;0; 'ethports.withrole.count'=3;;;0; 'ethports.ip.configured.count'=0;;;0;
