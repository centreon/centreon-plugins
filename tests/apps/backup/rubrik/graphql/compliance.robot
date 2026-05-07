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
...                 --mode=compliance
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --service-account=XXX
...                 --secret=XXX


*** Test Cases ***
Compliance ${tc}
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
    ...    CRITICAL: Total number of returned objects: 2 | 'objects.count'=2;;0:0;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    2
    ...    --object-type=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    3
    ...    --excluded-object-type=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    4
    ...    --object-state=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    5
    ...    --protection-status=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    6
    ...    --sla-domain-id=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    7
    ...    --include-object-id=Fileset:::122121-1221-42116-1221-2212121 --critical-objects-count=
    ...    OK: Total number of returned objects: 1 - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) compliance status: OUT_OF_COMPLIANCE, protection status: Protected | 'objects.count'=1;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    8
    ...    --exclude-object-id=Fileset:::122121-1221-42116-1221-2212121 --critical-objects-count=
    ...    OK: Total number of returned objects: 1 - object '/POBIEN1: **' (Fileset:::121221-1212-122112-1212-aaaaaaa) compliance status: OUT_OF_COMPLIANCE, protection status: Protected | 'objects.count'=1;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0;
    ...    9
    ...    --include-object-name=POBIEN --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    10
    ...    --exclude-object-name=POBIEN --critical-objects-count=
    ...    OK: Total number of returned objects: 0 | 'objects.count'=0;;;0;
    ...    11
    ...    --include-object-type=FILESET --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    12
    ...    --exclude-object-type=FILESET --critical-objects-count=
    ...    OK: Total number of returned objects: 0 | 'objects.count'=0;;;0;
    ...    13
    ...    --include-location=centreon --critical-objects-count=
    ...    OK: Total number of returned objects: 1 - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) compliance status: OUT_OF_COMPLIANCE, protection status: Protected | 'objects.count'=1;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    14
    ...    --exclude-location=test --critical-objects-count=
    ...    OK: Total number of returned objects: 1 - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) compliance status: OUT_OF_COMPLIANCE, protection status: Protected | 'objects.count'=1;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    15
    ...    --sla-domain-id=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    16
    ...    --compliance-status=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    17
    ...    --include-compliance-status=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 0 | 'objects.count'=0;;;0;
    ...    18
    ...    --exclude-compliance-status=1 --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    19
    ...    --time-range=PAST_7_DAYS --critical-objects-count=
    ...    OK: Total number of returned objects: 2 - All objects are ok | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    20
    ...    --unknown-status=1 --critical-objects-count=
    ...    UNKNOWN: object '/POBIEN1: **' (Fileset:::121221-1212-122112-1212-aaaaaaa) compliance status: OUT_OF_COMPLIANCE, protection status: Protected - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) compliance status: OUT_OF_COMPLIANCE, protection status: Protected | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    21
    ...    --warning-status=1 --critical-objects-count=
    ...    WARNING: object '/POBIEN1: **' (Fileset:::121221-1212-122112-1212-aaaaaaa) compliance status: OUT_OF_COMPLIANCE, protection status: Protected - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) compliance status: OUT_OF_COMPLIANCE, protection status: Protected | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    22
    ...    --critical-status=1 --critical-objects-count=
    ...    CRITICAL: object '/POBIEN1: **' (Fileset:::121221-1212-122112-1212-aaaaaaa) compliance status: OUT_OF_COMPLIANCE, protection status: Protected - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) compliance status: OUT_OF_COMPLIANCE, protection status: Protected | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    23
    ...    --warning-missed-snapshots=1 --critical-objects-count=
    ...    WARNING: object '/POBIEN1: **' (Fileset:::121221-1212-122112-1212-aaaaaaa) missed snapshots: 4 - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) missed snapshots: 4 | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;0:1;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;0:1;;0;
    ...    24
    ...    --critical-missed-snapshots=1 --critical-objects-count=
    ...    CRITICAL: object '/POBIEN1: **' (Fileset:::121221-1212-122112-1212-aaaaaaa) missed snapshots: 4 - object '/POBIEN: **' (Fileset:::122121-1221-42116-1221-2212121) missed snapshots: 4 | 'objects.count'=2;;;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;0:1;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;0:1;0;
    ...    25
    ...    --include-cluster=ddddd:cccc:bbbb:bbbb
    ...    CRITICAL: Total number of returned objects: 1 | 'objects.count'=1;;0:0;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
    ...    26
    ...    --exclude-cluster=TEST2
    ...    CRITICAL: Total number of returned objects: 2 | 'objects.count'=2;;0:0;0; 'Fileset:::121221-1212-122112-1212-aaaaaaa#object.snapshots.missed.count'=4;;;0; 'Fileset:::122121-1221-42116-1221-2212121#object.snapshots.missed.count'=4;;;0;
