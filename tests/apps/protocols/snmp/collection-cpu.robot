*** Settings ***
Documentation       Check cpu

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::protocols::snmp::plugin


*** Test Cases ***
Collection Cpu ${tc}
    [Tags]    snmp-collection
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=collection
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=apps/protocols/snmp/cpu
    ...    --config=tests/apps/protocols/snmp/cpu.json
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All selections are ok | '11#cpu.usage.percent'=2%;;;0;100 '12#cpu.usage.percent'=50%;;;0;100
    ...    2
    ...    --constant='warning=30'
    ...    WARNING: CPU '12' usage : 50 % | '11#cpu.usage.percent'=2%;30;;0;100 '12#cpu.usage.percent'=50%;30;;0;100
    ...    3
    ...    --constant='critical=45'
    ...    CRITICAL: CPU '12' usage : 50 % | '11#cpu.usage.percent'=2%;;45;0;100 '12#cpu.usage.percent'=50%;;45;0;100
