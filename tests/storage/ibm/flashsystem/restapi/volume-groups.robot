*** Settings ***
Documentation     storage::ibm::flashsystem::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}flashsystem.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=storage::ibm::flashsystem::restapi::plugin
...                --mode=volume-groups
...                --hostname=${HOSTNAME}
...                --proto=http
...                --port=${APIPORT}
...                --api-username=user
...                --api-password=pass
...                --statefile-dir=/tmp


*** Test Cases ***
volume-groups ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Volume groups: 34 detected, 33 replicated, 34 without a snapshot policy, 0 restoring - All volume groups are healthy | 'volumegroups.detected.count'=34;;;0; 'volumegroups.replicated.count'=33;;;0; 'volumegroups.without.snapshot.policy.count'=34;;;0; 'volumegroups.restoring.count'=0;;;0;
    ...    2
    ...    --include-partition='partition-a'
    ...    OK: Volume groups: 4 detected, 4 replicated, 4 without a snapshot policy, 0 restoring - All volume groups are healthy | 'volumegroups.detected.count'=4;;;0; 'volumegroups.replicated.count'=4;;;0; 'volumegroups.without.snapshot.policy.count'=4;;;0; 'volumegroups.restoring.count'=0;;;0;
    ...    3
    ...    --warning-without-snapshot-policy=0
    ...    WARNING: Volume groups: 34 without a snapshot policy | 'volumegroups.detected.count'=34;;;0; 'volumegroups.replicated.count'=33;;;0; 'volumegroups.without.snapshot.policy.count'=34;0:0;;0; 'volumegroups.restoring.count'=0;;;0;
    ...    4
    ...    --critical-status='\\\%{backup_status} =~ /off/' --include-name='^vg-0[1-2]$'
    ...    CRITICAL: Volume group 'vg-01' 28 volume(s), backup: off, partition: partition-a, replication: policy-a | 'volumegroups.detected.count'=2;;;0; 'volumegroups.replicated.count'=2;;;0; 'volumegroups.without.snapshot.policy.count'=2;;;0; 'volumegroups.restoring.count'=0;;;0;
    ...    5
    ...    --exclude-name='^vg-[0-2]'
    ...    OK: Volume groups: 5 detected, 4 replicated, 5 without a snapshot policy, 0 restoring - All volume groups are healthy | 'volumegroups.detected.count'=5;;;0; 'volumegroups.replicated.count'=4;;;0; 'volumegroups.without.snapshot.policy.count'=5;;;0; 'volumegroups.restoring.count'=0;;;0;

volume-groups discovery ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>partition_name</element> <element>volume_count</element> <element>replication_policy</element> </data>
    ...    2
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label name="vg-01" partition_name="partition-a" replication_policy="policy-a" volume_count="28"/> <label name="vg-02" partition_name="partition-a" replication_policy="policy-a" volume_count="0"/> <label name="vg-03" partition_name="partition-a" replication_policy="policy-a" volume_count="3"/> <label name="vg-04" partition_name="partition-a" replication_policy="policy-a" volume_count="4"/> <label name="vg-05" partition_name="partition-b" replication_policy="policy-a" volume_count="30"/> <label name="vg-06" partition_name="partition-b" replication_policy="policy-a" volume_count="6"/> <label name="vg-07" partition_name="partition-b" replication_policy="policy-a" volume_count="7"/> <label name="vg-08" partition_name="partition-b" replication_policy="policy-a" volume_count="10"/> <label name="vg-09" partition_name="partition-b" replication_policy="policy-a" volume_count="4"/> <label name="vg-10" partition_name="partition-b" replication_policy="policy-a" volume_count="16"/> <label name="vg-11" partition_name="partition-b" replication_policy="policy-a" volume_count="6"/> <label name="vg-12" partition_name="partition-b" replication_policy="policy-a" volume_count="2"/> <label name="vg-13" partition_name="partition-b" replication_policy="policy-a" volume_count="37"/> <label name="vg-14" partition_name="partition-b" replication_policy="policy-a" volume_count="5"/> <label name="vg-15" partition_name="partition-b" replication_policy="policy-a" volume_count="4"/> <label name="vg-16" partition_name="partition-b" replication_policy="policy-a" volume_count="16"/> <label name="vg-17" partition_name="partition-b" replication_policy="policy-a" volume_count="3"/> <label name="vg-18" partition_name="partition-b" replication_policy="policy-a" volume_count="2"/> <label name="vg-19" partition_name="partition-b" replication_policy="policy-a" volume_count="20"/> <label name="vg-20" partition_name="partition-b" replication_policy="policy-a" volume_count="5"/> <label name="vg-21" partition_name="partition-b" replication_policy="policy-a" volume_count="25"/> <label name="vg-22" partition_name="partition-b" replication_policy="policy-a" volume_count="7"/> <label name="vg-23" partition_name="partition-b" replication_policy="policy-a" volume_count="42"/> <label name="vg-24" partition_name="partition-b" replication_policy="policy-a" volume_count="2"/> <label name="vg-25" partition_name="partition-b" replication_policy="policy-a" volume_count="4"/> <label name="vg-26" partition_name="partition-b" replication_policy="policy-a" volume_count="8"/> <label name="vg-27" partition_name="partition-b" replication_policy="policy-a" volume_count="1"/> <label name="vg-28" partition_name="partition-b" replication_policy="policy-a" volume_count="1"/> <label name="vg-29" partition_name="partition-b" replication_policy="policy-a" volume_count="1"/> <label name="vg-30" partition_name="partition-b" replication_policy="policy-a" volume_count="13"/> <label name="vg-31" partition_name="partition-b" replication_policy="policy-a" volume_count="6"/> <label name="vg-32" partition_name="partition-b" replication_policy="policy-a" volume_count="25"/> <label name="vg-33" partition_name="partition-b" replication_policy="policy-a" volume_count="2"/> <label name="vg-34" partition_name="" replication_policy="" volume_count="3"/> </data>
