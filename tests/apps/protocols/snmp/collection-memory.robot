*** Settings ***
Documentation       Check memory

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::protocols::snmp::plugin


*** Test Cases ***
Collection Memory ${tc}
    [Tags]    snmp-collection
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=collection
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=apps/protocols/snmp/memo
    ...    --config=tests/apps/protocols/snmp/memory.json
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
    ...    OK: Memory 'Physical memory' usage : 1266544 / 2014256 | '1#memory.usage.bytes'=1266544;;;; '1#memory.size.bytes'=2014256;;;;
    ...    2
    ...    2c
    ...    --verbose
    ...    OK: Memory 'Physical memory' usage : 1266544 / 2014256 | '1#memory.usage.bytes'=1266544;;;; '1#memory.size.bytes'=2014256;;;; Memory 'Physical memory' usage : 1266544 / 2014256
    ...    3
    ...    2c
    ...    --constant='warning=30'
    ...    WARNING: Memory 'Physical memory' usage : 1266544 / 2014256 | '1#memory.usage.bytes'=1266544;;;; '1#memory.size.bytes'=2014256;;;;
    ...    4
    ...    2c
    ...    --constant='critical=45'
    ...    CRITICAL: Memory 'Physical memory' usage : 1266544 / 2014256 | '1#memory.usage.bytes'=1266544;;;; '1#memory.size.bytes'=2014256;;;;
