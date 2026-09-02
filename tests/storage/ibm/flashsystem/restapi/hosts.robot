*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=hosts
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
hosts ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                 expected_result    --
            ...       1       ${EMPTY}                                      WARNING: Host 'host-29' status: offline, ports: 4, partition: partition-b - Host 'host-43' status: offline, ports: 4, partition: partition-b - Host 'host-51' status: offline, ports: 4, partition: partition-b - Host 'host-54' status: offline, ports: 4, partition: partition-b | 'hosts.detected.count'=12;;;0; 'hosts.online.count'=8;;;0; 'hosts.offline.count'=4;;;0; 'hosts.degraded.count'=0;;;0;
            ...       2       --filter-partition='partition-a'              OK: Hosts: 8 declared, 8 online, 0 offline, 0 degraded - All hosts are online | 'hosts.detected.count'=8;;;0; 'hosts.online.count'=8;;;0; 'hosts.offline.count'=0;;;0; 'hosts.degraded.count'=0;;;0;
            ...       3       --critical-status='\\\%{status} =~ /offline/'    CRITICAL: Host 'host-29' status: offline, ports: 4, partition: partition-b - Host 'host-43' status: offline, ports: 4, partition: partition-b - Host 'host-51' status: offline, ports: 4, partition: partition-b - Host 'host-54' status: offline, ports: 4, partition: partition-b | 'hosts.detected.count'=12;;;0; 'hosts.online.count'=8;;;0; 'hosts.offline.count'=4;;;0; 'hosts.degraded.count'=0;;;0;
            ...       4       --filter-name='^host-2'                       WARNING: Host 'host-29' status: offline, ports: 4, partition: partition-b | 'hosts.detected.count'=1;;;0; 'hosts.online.count'=0;;;0; 'hosts.offline.count'=1;;;0; 'hosts.degraded.count'=0;;;0;
