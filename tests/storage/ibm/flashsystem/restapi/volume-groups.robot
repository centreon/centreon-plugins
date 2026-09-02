*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=volume-groups
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
volume-groups ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                                expected_result    --
            ...       1       ${EMPTY}                                                                     OK: Volume groups: 34 detected, 33 replicated, 34 without a snapshot policy, 0 restoring - All volume groups are healthy | 'volumegroups.detected.count'=34;;;0; 'volumegroups.replicated.count'=33;;;0; 'volumegroups.without.snapshot.policy.count'=34;;;0; 'volumegroups.restoring.count'=0;;;0;
            ...       2       --filter-partition='partition-a'                                             OK: Volume groups: 4 detected, 4 replicated, 4 without a snapshot policy, 0 restoring - All volume groups are healthy | 'volumegroups.detected.count'=4;;;0; 'volumegroups.replicated.count'=4;;;0; 'volumegroups.without.snapshot.policy.count'=4;;;0; 'volumegroups.restoring.count'=0;;;0;
            ...       3       --warning-without-snapshot-policy=0                                          WARNING: Volume groups: 34 without a snapshot policy | 'volumegroups.detected.count'=34;;;0; 'volumegroups.replicated.count'=33;;;0; 'volumegroups.without.snapshot.policy.count'=34;0:0;;0; 'volumegroups.restoring.count'=0;;;0;
            ...       4       --critical-status='\\\%{backup_status} =~ /off/' --filter-name='^vg-0[1-2]$'    CRITICAL: Volume group 'vg-01' 28 volume(s), backup: off, partition: partition-a, replication: policy-a | 'volumegroups.detected.count'=2;;;0; 'volumegroups.replicated.count'=2;;;0; 'volumegroups.without.snapshot.policy.count'=2;;;0; 'volumegroups.restoring.count'=0;;;0;
