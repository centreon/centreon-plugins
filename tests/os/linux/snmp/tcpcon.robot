*** Settings ***
Documentation       Check tcpcon table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
tcpcon ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=tcpcon
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp    ${output}    ${expected_result}

    Examples:        tc    extra_options                           expected_result    --
            ...      1     -application=[services]                 OK: Total connections: \\\\d+ \\\\| 'service_total'=\\\\d+;;;\\\\d+;
            ...      2     -application=[threshold-critical]       OK: Total connections: \\\\d+ \\\\| 'service_total'=\\\\d+;;;\\\\d+;
            ...      3     -application=[threshold-warning]        OK: Total connections: \\\\d+ \\\\| 'service_total'=\\\\d+;;;\\\\d+;
