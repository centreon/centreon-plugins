*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
list-services ${tc}
    [Tags]    os    Windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=list-services
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/services-en
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                  expected_result    --
            ...      1     --filter-name='Windows Security Service'       List services: [name = Windows Security Service] [operating = active] [installed = installed]
            ...      2     --filter-name='AVCTP service'                  List services: [name = AVCTP service] [operating = active] [installed = installed]
