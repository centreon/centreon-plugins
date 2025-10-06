*** Settings ***
Documentation       Check cpu

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::protocols::snmp::plugin


*** Test Cases ***
SNMP Collection${tc}
    [Tags]    snmp collection
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=collection
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=apps/protocols/snmp/cpu
    ...    --config=tests/apps/protocols/snmp/cpu.json

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --use-ucd='0'                   OK: All selections are ok | '11#cpu.usage.percent'=2%;;;0;100 '12#cpu.usage.percent'=50%;;;0;100
            ...      2     --warning-average               OK: All selections are ok | '11#cpu.usage.percent'=2%;;;0;100 '12#cpu.usage.percent'=50%;;;0;100
            ...      3     --critical-core='0'             OK: All selections are ok | '11#cpu.usage.percent'=2%;;;0;100 '12#cpu.usage.percent'=50%;;;0;100