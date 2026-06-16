*** Settings ***
Documentation       cloud::openshift::api::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}openshift.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::openshift::api::plugin
...                 --mode=projects
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --token=fake-token


*** Test Cases ***
Projects ${tc}
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
    ...    OK: Total: 65, Active: 65, Terminating: 0, Non-compliant: 0 | 'projects-total'=65;;;0; 'projects-active'=65;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    2
    ...    --include-name=openshift-node
    ...    OK: Total: 1, Active: 1, Terminating: 0, Non-compliant: 0 | 'projects-total'=1;;;0; 'projects-active'=1;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    3
    ...    --exclude-name=-
    ...    OK: Total: 2, Active: 2, Terminating: 0, Non-compliant: 0 | 'projects-total'=2;;;0; 'projects-active'=2;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    4
    ...    --include-label=kubernetes.io/metadata.name=openshift
    ...    OK: Total: 60, Active: 60, Terminating: 0, Non-compliant: 0 | 'projects-total'=60;;;0; 'projects-active'=60;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    5
    ...    --exclude-label=kubernetes.io/metadata.name=openshift
    ...    OK: Total: 5, Active: 5, Terminating: 0, Non-compliant: 0 | 'projects-total'=5;;;0; 'projects-active'=5;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    6
    ...    --required-label=fake --include-name=openshift-node
    ...    CRITICAL: Non-compliant: 1 | 'projects-total'=1;;;0; 'projects-active'=1;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=1;;@1:;0; Projects not respecting label policy (1): openshift-node
    ...    7
    ...    --warning-projects-total=1
    ...    WARNING: Total: 65 | 'projects-total'=65;0:1;;0; 'projects-active'=65;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    8
    ...    --critical-projects-total=1
    ...    CRITICAL: Total: 65 | 'projects-total'=65;;0:1;0; 'projects-active'=65;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    9
    ...    --warning-projects-active=@1 --include-name=openshift-apiserver-operator
    ...    WARNING: Active: 1 | 'projects-total'=1;;;0; 'projects-active'=1;@0:1;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0; Active projects (1): openshift-apiserver-operator
    ...    10
    ...    --critical-projects-active=@1 --include-name=openshift-apiserver-operator
    ...    CRITICAL: Active: 1 | 'projects-total'=1;;;0; 'projects-active'=1;;@0:1;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;@1:;0; Active projects (1): openshift-apiserver-operator
    ...    11
    ...    --warning-projects-terminating=1:
    ...    WARNING: Terminating: 0 | 'projects-total'=65;;;0; 'projects-active'=65;;;0; 'projects-terminating'=0;1:;;0; 'projects-noncompliant'=0;;@1:;0;
    ...    12
    ...    --critical-projects-terminating=1:
    ...    CRITICAL: Terminating: 0 | 'projects-total'=65;;;0; 'projects-active'=65;;;0; 'projects-terminating'=0;;1:;0; 'projects-noncompliant'=0;;@1:;0;
    ...    13
    ...    --warning-projects-noncompliant=1:
    ...    WARNING: Non-compliant: 0 | 'projects-total'=65;;;0; 'projects-active'=65;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;1:;@1:;0;
    ...    14
    ...    --critical-projects-noncompliant=1:
    ...    CRITICAL: Non-compliant: 0 | 'projects-total'=65;;;0; 'projects-active'=65;;;0; 'projects-terminating'=0;;;0; 'projects-noncompliant'=0;;1:;0;
    ...    15
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>uid</element> <element>name</element> <element>display_name</element> <element>phase</element> </data>
    ...    16
    ...    --disco-show --include-name=openshift-node
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label display_name="openshift-node" name="openshift-node" phase="active" uid="5f5ca1d2-ae3b-4198-8abc-bdcdd690ebcf"/> </data>
