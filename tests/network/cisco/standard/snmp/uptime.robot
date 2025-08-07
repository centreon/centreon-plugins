*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
uptime ${tc}
    [Tags]    network    uptime    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     ${EMPTY}                                                              OK: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;;;0;
            ...      2     --warning-uptime=2000                                                 WARNING: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;0:2000;;0;
            ...      3     --critical-uptime=5000                                                CRITICAL: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;;0:5000;0;
            ...      4     --add-sysdesc                                                         OK: System uptime is: 19d 16h 25m 40s, Anonymized 023Technical Support: http://www.cisco.com/techsupport | 'uptime'=1700740.00s;;;0;
            ...      5     --force-oid='.1.3.6.1.2.1.2.2.1.3.181'                                OK: System uptime is: 0d | 'uptime'=0.00s;;;0;
            ...      6     --check-overload --reboot-window=1000                                 OK: System uptime is: 19d 16h 25m 40s | 'uptime'=1700740.00s;;;0;
            ...      7     --unit='w'                                                            OK: System uptime is: 19d 16h 25m 40s | 'uptime'=2.81w;;;0;