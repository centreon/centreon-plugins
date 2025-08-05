*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::mikrotik::snmp::plugin


*** Test Cases ***
listlteinterfaces ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-lte-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/mikrotik/snmp/mikrotik-chateau-lte6
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                expected_result    --
            ...      1     ${EMPTY}                                                     List interfaces: 'lte1' [speed = ][status = up][id = 9]
            ...      2     --filter-status='down'                                       List interfaces: skipping interface 'lte1': no matching filter status