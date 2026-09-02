*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=replication
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
replication ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                            expected_result    --
            ...       1       ${EMPTY}                                                 CRITICAL: Storage partition 'partition-b' high availability status: problem, link: synchronized, system-a: healthy, system-b: healthy | 'replication.partitions.detected.count'=2;;;0; 'replication.volumegroups.detected.count'=33;;;0; 'replication.relationships.detected.count'=0;;;0;
            ...       2       --filter-partition='partition-a'                         OK: Replication: 1 partition(s), 4 replicated volume group(s), 0 remote copy relationship(s) - Storage partition 'partition-a' high availability status: established, link: synchronized, system-a: healthy, system-b: healthy - All replicated volume groups are healthy - Partnership 'system-b' partnership: fully_configured, type: fc | 'replication.partitions.detected.count'=1;;;0; 'replication.volumegroups.detected.count'=4;;;0; 'replication.relationships.detected.count'=0;;;0;
            ...       3       --critical-partition-status='\\\%{ha_status} =~ /never/'    OK: Replication: 2 partition(s), 33 replicated volume group(s), 0 remote copy relationship(s) - All storage partitions are healthy - All replicated volume groups are healthy - Partnership 'system-b' partnership: fully_configured, type: fc | 'replication.partitions.detected.count'=2;;;0; 'replication.volumegroups.detected.count'=33;;;0; 'replication.relationships.detected.count'=0;;;0;
            ...       4       --filter-partnership='nomatch'                           CRITICAL: Storage partition 'partition-b' high availability status: problem, link: synchronized, system-a: healthy, system-b: healthy | 'replication.partitions.detected.count'=2;;;0; 'replication.volumegroups.detected.count'=33;;;0; 'replication.relationships.detected.count'=0;;;0;
