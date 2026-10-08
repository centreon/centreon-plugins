*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=volumes
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
volumes ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                             expected_result    --
            ...       1       ${EMPTY}                                                                  OK: Volumes: 20 detected, 20 online, 0 degraded, 0 offline, 0 with copies out of sync | 'volumes.detected.count'=20;;;0; 'volumes.online.count'=20;;;0; 'volumes.degraded.count'=0;;;0; 'volumes.offline.count'=0;;;0; 'volumes.unsynchronised.count'=0;;;0;
            ...       2       --filter-name='^vol-00[1-3]$'                                             OK: Volumes: 3 detected, 3 online, 0 degraded, 0 offline, 0 with copies out of sync | 'volumes.detected.count'=3;;;0; 'volumes.online.count'=3;;;0; 'volumes.degraded.count'=0;;;0; 'volumes.offline.count'=0;;;0; 'volumes.unsynchronised.count'=0;;;0;
            ...       3       --add-all-volumes                                                         OK: Volumes: 20 detected, 20 online, 0 degraded, 0 offline, 0 with copies out of sync - All volumes are online and synchronised | 'volumes.detected.count'=20;;;0; 'volumes.online.count'=20;;;0; 'volumes.degraded.count'=0;;;0; 'volumes.offline.count'=0;;;0; 'volumes.unsynchronised.count'=0;;;0;
            ...       4       --warning-status='\\\%{status} =~ /online/' --filter-name='^vol-00[1-2]$'    OK: Volumes: 2 detected, 2 online, 0 degraded, 0 offline, 0 with copies out of sync | 'volumes.detected.count'=2;;;0; 'volumes.online.count'=2;;;0; 'volumes.degraded.count'=0;;;0; 'volumes.offline.count'=0;;;0; 'volumes.unsynchronised.count'=0;;;0;
