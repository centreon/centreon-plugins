*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=fc-ports
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
fc-ports ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                 expected_result    --
            ...       1       ${EMPTY}                                      OK: Fibre Channel ports: 8 detected, 8 active, 0 inactive, 648 host login(s) - All Fibre Channel ports are active | 'fcports.detected.count'=8;;;0; 'fcports.active.count'=8;;;0; 'fcports.inactive.count'=0;;;0; 'fcports.host.logins.count'=648;;;0;
            ...       2       --filter-name='^node1'                        OK: Fibre Channel ports: 4 detected, 4 active, 0 inactive, 324 host login(s) - All Fibre Channel ports are active | 'fcports.detected.count'=4;;;0; 'fcports.active.count'=4;;;0; 'fcports.inactive.count'=0;;;0; 'fcports.host.logins.count'=324;;;0;
            ...       3       --critical-host-logins=10                     CRITICAL: Fibre Channel ports: 648 host login(s) | 'fcports.detected.count'=8;;;0; 'fcports.active.count'=8;;;0; 'fcports.inactive.count'=0;;;0; 'fcports.host.logins.count'=648;;0:10;0;
            ...       4       --warning-status='\\\%{port_speed} =~ /16Gb/'    WARNING: Port 'node1-1' status: active, speed: 16Gb, attachment: switch, host logins: 6 - Port 'node1-2' status: active, speed: 16Gb, attachment: switch, host logins: 6 - Port 'node1-3' status: active, speed: 16Gb, attachment: switch, host logins: 156 - Port 'node1-4' status: active, speed: 16Gb, attachment: switch, host logins: 156 - Port 'node2-1' status: active, speed: 16Gb, attachment: switch, host logins: 6 - Port 'node2-2' status: active, speed: 16Gb, attachment: switch, host logins: 6 - Port 'node2-3' status: active, speed: 16Gb, attachment: switch, host logins: 156 - Port 'node2-4' status: active, speed: 16Gb, attachment: switch, host logins: 156 | 'fcports.detected.count'=8;;;0; 'fcports.active.count'=8;;;0; 'fcports.inactive.count'=0;;;0; 'fcports.host.logins.count'=648;;;0;
