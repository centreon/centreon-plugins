*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=hardware
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
hardware ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                         expected_result    --
            ...       1       ${EMPTY}                                              OK: Hardware: 35 component(s), 0 not online - All hardware components are online - Enclosure: temperature 26 C, power draw 543 W - All enclosure subsystems are fully populated | 'hardware.components.detected.count'=35;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
            ...       2       --filter-type='quorum'                                OK: Hardware: 6 component(s), 0 not online - All hardware components are online - Enclosure: temperature 26 C, power draw 543 W | 'hardware.components.detected.count'=6;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
            ...       3       --warning-component-status='\\\%{status} =~ /online/'    WARNING: Array 'MDisk1' status: online - Battery '1' status: online - Battery '2' status: online - Drive '0' status: online - Drive '1' status: online - Drive '10' status: online - Drive '11' status: online - Drive '2' status: online - Drive '3' status: online - Drive '4' status: online - Drive '5' status: online - Drive '6' status: online - Drive '7' status: online - Drive '8' status: online - Drive '9' status: online - Enclosure '1' status: online - Expansion canister '1' status: online - Expansion canister '2' status: online - Fan module '1' status: online - Fan module '2' status: online - Fan module '3' status: online - Fan module '4' status: online - Fan module '5' status: online - Fan module '6' status: online - Mdisk 'MDisk1' status: online - Node canister 'node1' status: online - Node canister 'node2' status: online - Power supply '1' status: online - Power supply '2' status: online - Quorum '0' status: online - Quorum '1' status: online - Quorum '10' status: online - Quorum '2' status: online - Quorum '8' status: online - Quorum '9' status: online | 'hardware.components.detected.count'=35;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
            ...       4       --warning-temperature=10 --critical-temperature=20    CRITICAL: Enclosure: temperature 26 C | 'hardware.components.detected.count'=35;;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;0:10;0:20;; 'hardware.power.watt'=543W;;;0;
            ...       5       --warning-components-detected=10                      WARNING: Hardware: 35 component(s) | 'hardware.components.detected.count'=35;0:10;;0; 'hardware.components.degraded.count'=0;;;0; 'hardware.temperature.celsius'=26C;;;; 'hardware.power.watt'=543W;;;0;
