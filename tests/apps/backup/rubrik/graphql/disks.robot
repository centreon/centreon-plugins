*** Settings ***
Documentation       apps::backup::rubrik::graphql::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}rubrik-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::rubrik::graphql::plugin
...                 --mode=disks
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --service-account=XXX
...                 --secret=XXX


*** Test Cases ***
Disks ${tc}
    [Tags]    apps    backup    graphql
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
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    2
    ...    --start-time=2020-01-01 --end-time=2030-02-02
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    3
    ...    --last=99999m
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    4
    ...    --include-disk-id=zzazaz-azab-zazbf-azazaz26-zzazazza
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=0;;;0; 'TEST-IN#cluster.disks.active.count'=0;;;0;0 'TEST-VI#cluster.disks.total.count'=0;;;0; 'TEST-VI#cluster.disks.active.count'=0;;;0;0 'TEST-OS#cluster.disks.total.count'=0;;;0; 'TEST-OS#cluster.disks.active.count'=0;;;0;0
    ...    5
    ...    --exclude-disk-id=zzazaz-azab-zazbf-azazaz26-zzazazza
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    6
    ...    --include-disk-path=ekek
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=0;;;0; 'TEST-IN#cluster.disks.active.count'=0;;;0;0 'TEST-VI#cluster.disks.total.count'=1;;;0; 'TEST-VI#cluster.disks.active.count'=1;;;0;1 'TEST-OS#cluster.disks.total.count'=0;;;0; 'TEST-OS#cluster.disks.active.count'=0;;;0;0
    ...    7
    ...    --exclude-disk-path=ekek
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=2;;;0; 'TEST-VI#cluster.disks.active.count'=2;;;0;2 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    8
    ...    --unknown-disk-status=1
    ...    UNKNOWN: Cluster 'TEST-IN' Disk 'sda' status: active - Disk 'sdb' status: active - Cluster 'TEST-VI' Disk 'sda' status: active - Disk 'sdb' status: active - Disk 'sdc' status: active - Cluster 'TEST-OS' Disk 'sda' status: active - Disk 'sdb' status: active | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    9
    ...    --warning-disk-status=1
    ...    WARNING: Cluster 'TEST-IN' Disk 'sda' status: active - Disk 'sdb' status: active - Cluster 'TEST-VI' Disk 'sda' status: active - Disk 'sdb' status: active - Disk 'sdc' status: active - Cluster 'TEST-OS' Disk 'sda' status: active - Disk 'sdb' status: active | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    10
    ...    --critical-disk-status=1
    ...    CRITICAL: Cluster 'TEST-IN' Disk 'sda' status: active - Disk 'sdb' status: active - Cluster 'TEST-VI' Disk 'sda' status: active - Disk 'sdb' status: active - Disk 'sdc' status: active - Cluster 'TEST-OS' Disk 'sda' status: active - Disk 'sdb' status: active | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    11
    ...    --warning-cluster-disks-total=1
    ...    WARNING: Cluster 'TEST-IN' disks total 2 - Cluster 'TEST-VI' disks total 3 - Cluster 'TEST-OS' disks total 2 | 'TEST-IN#cluster.disks.total.count'=2;0:1;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;0:1;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;0:1;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    12
    ...    --critical-cluster-disks-total=1
    ...    CRITICAL: Cluster 'TEST-IN' disks total 2 - Cluster 'TEST-VI' disks total 3 - Cluster 'TEST-OS' disks total 2 | 'TEST-IN#cluster.disks.total.count'=2;;0:1;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;0:1;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;0:1;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
    ...    13
    ...    --warning-cluster-disks-active=1
    ...    WARNING: Cluster 'TEST-IN' disks active 2 - Cluster 'TEST-VI' disks active 3 - Cluster 'TEST-OS' disks active 2 | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;0:1;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;0:1;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;0:1;;0;2
    ...    14
    ...    --critical-cluster-disks-active=1
    ...    CRITICAL: Cluster 'TEST-IN' disks active 2 - Cluster 'TEST-VI' disks active 3 - Cluster 'TEST-OS' disks active 2 | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;0:1;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;0:1;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;0:1;0;2
    ...    15
    ...    --include-cluster=TEST-IN
    ...    OK: Cluster 'TEST-IN' disks are ok | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2
    ...    16
    ...    --exclude-cluster=zzazaza-dfdf-42323-11116-ezezzeez
    ...    OK: All disks are ok | 'TEST-IN#cluster.disks.total.count'=2;;;0; 'TEST-IN#cluster.disks.active.count'=2;;;0;2 'TEST-VI#cluster.disks.total.count'=3;;;0; 'TEST-VI#cluster.disks.active.count'=3;;;0;3 'TEST-OS#cluster.disks.total.count'=2;;;0; 'TEST-OS#cluster.disks.active.count'=2;;;0;2
