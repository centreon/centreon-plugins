*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
time ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=time
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    ${extra_options}
 

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --oid=''                        OK:
            ...      2     --warning-offset='0'            WARNING:
            ...      3     --critical-offset='125'         CRITICAL: 
            ...      4     --ntp-port=123                  OK: 
            ...      5     --timezone='+0100'              OK:
            ...      6     --ntp-hostname                  OK:
            ...      7     --verbose                       ok
            ...      8     --debug                         ok