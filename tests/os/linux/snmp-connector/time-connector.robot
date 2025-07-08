*** Settings ***
Documentation       Check time table
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Connector
Suite Teardown      Stop Connector
Test Timeout        120s


*** Variables ***
${CMD}      /usr/lib/centreon/plugins/centreon_linux_snmp.pl --plugin=os::linux::snmp::plugin


*** Test Cases ***
time ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=time
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=5
    ...    ${extra_options}

    Ctn Run Command With Connector And Check Result As Regexp    ${tc}    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --oid=''                        OK: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      2     --warning-offset='0'            WARNING: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      3     --critical-offset='125'         CRITICAL: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      4     --ntp-port=123                  OK: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$
            ...      5     --timezone='+0100'              OK: Time offset (-?\\\\d+) second\\\\(s\\\\): Local Time : (\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}) \\\\(\\\\+\\\\d{4}\\\\) \\\\| 'offset'=(-?\\\\d+)s;.*$