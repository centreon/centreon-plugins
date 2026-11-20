*** Settings ***
Documentation     Hardware UPS powerware SNMP plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS} --plugin=hardware::ups::powerware::snmp::plugin
...       --mode=alarms
...       --hostname=${HOSTNAME}
...       --snmp-version=${SNMPVERSION}
...       --snmp-port=${SNMPPORT}
...       --snmp-timeout=1


*** Test Cases ***
Hardware UPS Powerware SNMP alarms ${tc}
    [Tags]    hardware    ups    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=${snmpcommunity}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    snmpcommunity
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    hardware/ups/powerware/snmp/alarms
    ...    ${EMPTY}
    ...    CRITICAL: 1 problem detected (use verbose for more details)
    ...    2
    ...    hardware/ups/powerware/snmp/alarms
    ...    --verbose
    ...    CRITICAL: 1 problem detected (use verbose for more details) 0 day(s), 0:0:0 : OutputNotProtected Number of message checked: 1
    ...    3
    ...    hardware/ups/powerware/snmp/alarms
    ...    --warning
    ...    WARNING: 1 problem detected (use verbose for more details)
    ...    4
    ...    hardware/ups/powerware/snmp/alarms
    ...    --filter-type='^(?!OutputNotProtected)'
    ...    OK: No problems detected.
    ...    5
    ...    hardware/ups/powerware/snmp/alarms-unknown
    ...    --verbose
    ...    CRITICAL: 1 problem detected (use verbose for more details) 1 day(s), 0:0:0 : Unknown(.1.3.6.1.4.1.534.1.7.99) Number of message checked: 1
