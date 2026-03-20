*** Settings ***
Resource        ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup     Ctn Generic Suite Setup
Test Timeout    120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::aix::snmp::plugin


*** Test Cases ***
interfaces ${tc}
    [Tags]    os    aix
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/aix/snmp/aix
    ...    --snmp-timeout=5
    ...    ${extra_options}

    # first run to build cache
    Run    ${command}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Interface 'en0' Status : up (admin: up)
    ...    2
    ...    --warning-status='\\\%{admstatus} eq "up"'
    ...    WARNING: Interface 'en0' Status : up (admin: up)
    ...    3
    ...    --critical-status='\\\%{admstatus} eq "up"'
    ...    CRITICAL: Interface 'en0' Status : up (admin: up)
    ...    4
    ...    --display-transform-src='en0' --display-transform-dst='test'
    ...    OK: Interface 'test' Status : up (admin: up)
