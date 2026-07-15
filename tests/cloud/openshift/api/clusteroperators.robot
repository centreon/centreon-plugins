*** Settings ***
Documentation       cloud::openshift::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openshift.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::openshift::api::plugin
...                 --mode=clusteroperators
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --token=fake-token


*** Test Cases ***
Clusteroperators ${tc}
    [Tags]    cloud    openshift    api
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
    ...    OK: Total: 24, Available: 24, Unavailable: 0, Degraded: 0, Progressing: 0, Not upgradeable: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    2
    ...    --include-name=kube-scheduler
    ...    OK: Total: 1, Available: 1, Unavailable: 0, Degraded: 0, Progressing: 0, Not upgradeable: 0 | 'clusteroperators-total'=1;;;0; 'clusteroperators-available'=1;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    3
    ...    --exclude-name=-
    ...    OK: Total: 7, Available: 7, Unavailable: 0, Degraded: 0, Progressing: 0, Not upgradeable: 0 | 'clusteroperators-total'=7;;;0; 'clusteroperators-available'=7;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    4
    ...    --warning-clusteroperators-total=1
    ...    WARNING: Total: 24 | 'clusteroperators-total'=24;0:1;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    5
    ...    --critical-clusteroperators-total=1
    ...    CRITICAL: Total: 24 | 'clusteroperators-total'=24;;0:1;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    6
    ...    --warning-clusteroperators-available=1 --exclude-name=-
    ...    WARNING: Available: 7 | 'clusteroperators-total'=7;;;0; 'clusteroperators-available'=7;0:1;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0; Available operators (7): authentication console dns etcd ingress marketplace network
    ...    7
    ...    --critical-clusteroperators-available=0 --include-name=openshift-samples
    ...    CRITICAL: Available: 1 | 'clusteroperators-total'=1;;;0; 'clusteroperators-available'=1;;0:0;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0; Available operators (1): openshift-samples
    ...    8
    ...    --warning-clusteroperators-unavailable=1:
    ...    WARNING: Unavailable: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;1:;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    9
    ...    --critical-clusteroperators-unavailable=1:
    ...    CRITICAL: Unavailable: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    10
    ...    --warning-clusteroperators-degraded=1:
    ...    WARNING: Degraded: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;1:;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    11
    ...    --critical-clusteroperators-degraded=1:
    ...    CRITICAL: Degraded: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;1:;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    12
    ...    --warning-clusteroperators-progressing=1:
    ...    WARNING: Progressing: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;1:;;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    13
    ...    --critical-clusteroperators-progressing=1:
    ...    CRITICAL: Progressing: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;1:;0; 'clusteroperators-not-upgradeable'=0;;;0;
    ...    14
    ...    --warning-clusteroperators-not-upgradeable=1:
    ...    WARNING: Not upgradeable: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;1:;;0;
    ...    15
    ...    --critical-clusteroperators-not-upgradeable=1:
    ...    CRITICAL: Not upgradeable: 0 | 'clusteroperators-total'=24;;;0; 'clusteroperators-available'=24;;;0; 'clusteroperators-unavailable'=0;;@1:;0; 'clusteroperators-degraded'=0;;;0; 'clusteroperators-progressing'=0;;;0; 'clusteroperators-not-upgradeable'=0;;1:;0;
