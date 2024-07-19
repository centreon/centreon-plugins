*** Settings ***
Documentation       HPE Primera Storage

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-primera.mockoon.json
${HOSTNAME}             127.0.0.1
${APIPORT}              3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=storage::hp::primera::restapi::plugin
...                 --mode=licenses
...                 --hostname=${HOSTNAME}
...                 --api-username=toto
...                 --api-password=toto
...                 --proto=http
...                 --port=${APIPORT}
...                 --custommode=api
...                 --statefile-dir=/dev/shm/

*** Test Cases ***
Licenses ${tc}
    [Tags]    storage     api    hpe    hp
    ${output}    Run    ${CMD} ${extraoptions}

    ${output}    Strip String    ${output}

    Should Match Regexp
    ...    ${output}
    ...    ${expected_result}
    ...    Wrong output result for command:\n${CMD} ${extraoptions}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False

    Examples:    tc        extraoptions                                                                                     expected_result   --
        ...      1        ${EMPTY}                                                                                          OK: Number of licenses: 25, Number of expired licenses: 1 - All licenses are ok \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;;;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;;;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;;;0;
        ...      2        --critical-license-expiration=86400:                                                              CRITICAL: License 'Adaptive Flash Cache' expires: 2024-07-14. Adaptive Flash Cache license has expired. \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;;;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;;86400:;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;;86400:;0;
        ...      3        --warning-license-expiration=86400:                                                               WARNING: License 'Adaptive Flash Cache' expires: 2024-07-14. Adaptive Flash Cache license has expired. \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;;;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;86400:;;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;86400:;;0;
        ...      4        --warning-expired=0:0                                                                             WARNING: Number of expired licenses: 1 \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;0:0;;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;;;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;;;0;
        ...      5        --critical-license-expiration=86400: --warning-license-expiration=1296000:                        CRITICAL: License 'Adaptive Flash Cache' expires: 2024-07-14. Adaptive Flash Cache license has expired. \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;;;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;1296000:;86400:;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;1296000:;86400:;0;
        ...      6        --critical-license-expiration=86400: --warning-license-expiration=86400:                          CRITICAL: License 'Adaptive Flash Cache' expires: 2024-07-14. Adaptive Flash Cache license has expired. \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;;;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;86400:;86400:;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;86400:;86400:;0;
        ...      7        --critical-license-expiration=86400: --warning-license-expiration=1296000: --warning-expired=0:0  CRITICAL: License 'Adaptive Flash Cache' expires: 2024-07-14. Adaptive Flash Cache license has expired. WARNING: Number of expired licenses: 1 \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;0:0;;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;1296000:;86400:;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;1296000:;86400:;0;
        ...      8        --critical-expired=0:0                                                                            CRITICAL: Number of expired licenses: 1 \| 'licenses.total.count'=25;;;0; 'licenses.expired.count'=1;;0:0;0;25 'Adaptive Flash Cache#Adaptive Flash Cache#license.expiration.seconds'=0s;;;0; 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;;;0;
        ...      9        --filter-name='Autonomic Rebalance'                                                               OK: Number of licenses: 1, Number of expired licenses: 0 - License 'Autonomic Rebalance' expires: 2284-05-21. Autonomic Rebalance license expires in .*. \| 'licenses.total.count'=1;;;0; 'licenses.expired.count'=0;;;0;1 'Autonomic Rebalance#Autonomic Rebalance#license.expiration.seconds'=[0-9]+s;;;0;
