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
...                 --mode=clusterversion
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --token=fake-token


*** Test Cases ***
Clusterversion ${tc}
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
    ...    OK: OpenShift 4.21.14 [stable-4.21] - Available, Not Upgradeable (ClusterVersionOverridesSet) | 'available'=1;;;0;1 'progressing'=0;;;0;1 'failing'=0;;;0;1 'upgradeable'=0;;;0;1 'retrievedupdates'=1;;;0;1 'updates_available'=3;;;0;
    ...    2
    ...    --critical-status='\\\%{available} =~ /true/'
    ...    CRITICAL: OpenShift 4.21.14 [stable-4.21] - Available, Not Upgradeable (ClusterVersionOverridesSet) | 'available'=1;;;0;1 'progressing'=0;;;0;1 'failing'=0;;;0;1 'upgradeable'=0;;;0;1 'retrievedupdates'=1;;;0;1 'updates_available'=3;;;0;
    ...    3
    ...    --warning-status='\\\%{available} =~ /true/'
    ...    WARNING: OpenShift 4.21.14 [stable-4.21] - Available, Not Upgradeable (ClusterVersionOverridesSet) | 'available'=1;;;0;1 'progressing'=0;;;0;1 'failing'=0;;;0;1 'upgradeable'=0;;;0;1 'retrievedupdates'=1;;;0;1 'updates_available'=3;;;0;
