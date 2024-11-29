*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::windows::snmp::plugin

*** Test Cases ***
time ${tc}
    [Tags]    os    Windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=time
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Match Regexp    ${output}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --oid=''                        OK: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      2     --warning-offset='0'            WARNING: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      3     --critical-offset='125'         CRITICAL: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      4     --ntp-port=123                  OK: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      5     --timezone='+0100'              OK: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
