*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     ${EMPTY}                                                              List interfaces: 'en0' [speed = 1500][status = up][id = 1][type = ethernetCsmacd]
