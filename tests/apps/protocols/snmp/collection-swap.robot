*** Settings ***
Documentation       Check memory

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::protocols::snmp::plugin


*** Test Cases ***
Collection Swap 32bits ${tc}
    [Tags]    snmp-collection
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=collection
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=apps/protocols/snmp/swap
    ...    --config=src/contrib/collection/snmp/swap.json
    ...    --snmp-version=${snmpver}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    snmpver
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    1
    ...    ${EMPTY}
    ...    OK: Swap usage: 5.94% (58 MB) | 'swap.usage.bytes'=59392;;;0;999420 'swap.usage.percent'=5.94;;;0;100
    ...    2
    ...    2c
    ...    --verbose
    ...    OK: Swap usage: 5.94% (58 MB) | 'swap.usage.bytes'=59392;;;0;999420 'swap.usage.percent'=5.94;;;0;100 Swap usage: 5.94% (58 MB)
    ...    3
    ...    2c
    ...    --constant='warning=3'
    ...    WARNING: Swap usage: 5.94% (58 MB) | 'swap.usage.bytes'=59392;;;0;999420 'swap.usage.percent'=5.94;3;;0;100
    ...    4
    ...    2c
    ...    --constant='critical=4'
    ...    CRITICAL: Swap usage: 5.94% (58 MB) | 'swap.usage.bytes'=59392;;;0;999420 'swap.usage.percent'=5.94;;4;0;100

Collection Swap 64bits ${tc}
    [Tags]    snmp-collection
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=collection
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=apps/protocols/snmp/swap
    ...    --config=src/contrib/collection/snmp/swap-64.json
    ...    --snmp-version=${snmpver}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    snmpver
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    1
    ...    ${EMPTY}
    ...    UNKNOWN: Unsafe code evaluation: syntax error at (eval 30) line 1, at EOF
    ...    2
    ...    2c
    ...    --verbose
    ...    OK: Swap usage: 5.94% (58 MB) | 'swap.usage.bytes'=59392;;;0;999420 'swap.usage.percent'=5.94;;;0;100 Swap usage: 5.94% (58 MB)
    ...    3
    ...    2c
    ...    --constant='warning=3'
    ...    WARNING: Swap usage: 5.94% (58 MB) | 'swap.usage.bytes'=59392;;;0;999420 'swap.usage.percent'=5.94;3;;0;100
    ...    4
    ...    2c
    ...    --constant='critical=4'
    ...    CRITICAL: Swap usage: 5.94% (58 MB) | 'swap.usage.bytes'=59392;;;0;999420 'swap.usage.percent'=5.94;;4;0;100
