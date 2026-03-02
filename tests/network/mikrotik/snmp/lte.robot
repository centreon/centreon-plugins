*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::mikrotik::snmp::plugin


*** Test Cases ***
lte ${tc}
    [Tags]    network    mikrotik    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=lte
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/mikrotik/snmp/mikrotik-chateau-lte6
    ...    --snmp-timeout=1
    ...    ${extra_options}

    # first run to build cache
    Run    ${command}
    # second run to control the output
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc     extra_options                                                 expected_result    --
            ...      1      ${EMPTY}                                                      OK: Current operator 'Centreon' IMSI: '0123456789' ICCID: '0123456789'
            ...      2      --warning-status='\\\%{current_operator} ne "Centreon1"'         WARNING: Current operator 'Centreon' IMSI: '0123456789' ICCID: '0123456789'
            ...      3      --warning-status='\\\%{imsi} ne "XXXX"'                          WARNING: Current operator 'Centreon' IMSI: '0123456789' ICCID: '0123456789'
            ...      4      --warning-status='\\\%{iccd} ne "XXXX"'                          WARNING: Current operator 'Centreon' IMSI: '0123456789' ICCID: '0123456789'
