*** Settings ***
Documentation       Check system uptime.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::aruba::aoscx::snmp::plugin

*** Test Cases ***
uptime ${tc}
    [Tags]    network    aruba    uptime
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/aruba/aoscx/snmp/slim_aoscx-spanning-tree
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                           expected_result    --
            ...      1     ${EMPTY}                                                                                                OK: System uptime is: 273d 7h 15m 11s | 'uptime'=23613311.00s;;;0;
            ...      2     --warning-uptime=1.1                                                                                    WARNING: System uptime is: 273d 7h 15m 11s | 'uptime'=23613311.00s;0:1.1;;0;
            ...      3     --critical-uptime=12                                                                                    CRITICAL: System uptime is: 273d 7h 15m 11s | 'uptime'=23613311.00s;;0:12;0;
            ...      4     --add-sysdesc                                                                                           OK: System uptime is: 273d 7h 15m 11s, Anonymized 023 | 'uptime'=23613311.00s;;;0;
            ...      5     --force-oid='.1.3.6.1.2.1.31.1.1.1.11.3'                                                                OK: System uptime is: 4901d 16h 34m 17s | 'uptime'=423506057.00s;;;0;
            ...      6     --check-overload --reboot-window=4294967297                                                             OK: System uptime is: 273d 7h 15m 11s | 'uptime'=23613311.00s;;;0;
            ...      7     --reboot-window=100000                                                                                  OK: System uptime is: 273d 7h 15m 11s | 'uptime'=23613311.00s;;;0;
            ...      8     --unit='s'                                                                                              OK: System uptime is: 273d 7h 15m 11s | 'uptime'=23613311.00s;;;0;