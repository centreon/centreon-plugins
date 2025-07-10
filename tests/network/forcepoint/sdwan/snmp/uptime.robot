*** Settings ***
Documentation       Forcepoint SD-WAN Mode Uptime

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
uptime ${tc}
    [Tags]    network    forcepoint    sdwan     snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=40000
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint-uptime
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --warning-uptime='2'            WARNING: System uptime is: 23h 52m 10s | 'uptime'=85930.00s;0:2;;0;
            ...      2     --warning-uptime='1'            WARNING: System uptime is: 23h 52m 10s | 'uptime'=85930.00s;0:1;;0;
            ...      3     --critical-uptime='2'           CRITICAL: System uptime is: 23h 52m 10s | 'uptime'=85930.00s;;0:2;0;
            ...      4     --add-sysdesc                   OK: System uptime is: 23h 52m 10s, Anonymized 023 | 'uptime'=85930.00s;;;0;
            ...      5     --critical-uptime='1'           CRITICAL: System uptime is: 23h 52m 10s | 'uptime'=85930.00s;;0:1;0;
            ...      6     --check-overload                OK: System uptime is: 23h 52m 10s | 'uptime'=85930.00s;;;0;
            ...      7     --reboot-window                 OK: System uptime is: 23h 52m 10s | 'uptime'=85930.00s;;;0;
            ...      8     --unit='h'                      OK: System uptime is: 23h 52m 10s | 'uptime'=23.87h;;;0;
            ...      9     --unit='m'                      OK: System uptime is: 23h 52m 10s | 'uptime'=1432.17m;;;0;
            ...      10    --unit='s'                      OK: System uptime is: 23h 52m 10s | 'uptime'=85930.00s;;;0;
