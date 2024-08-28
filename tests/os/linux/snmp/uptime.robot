*** Settings ***
Documentation       Check uptime table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
uptime ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --warning-uptime='2'            WARNING: System uptime is: 38m 39s | 'uptime'=2319.00s;0:2;;0; 
            ...      2     --warning-uptime='1'            WARNING: System uptime is: 38m 39s | 'uptime'=2319.00s;0:1;;0;
            ...      3     --critical-uptime='2'           CRITICAL: System uptime is: 38m 39s | 'uptime'=2319.00s;;0:2;0;
            ...      4     --add-sysdesc                   OK: System uptime is: 38m 39s, Linux central-deb-24-04 6.1.0-23-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.99-1 (2024-07-15) x86_64 | 'uptime'=2319.00s;;;0; 
            ...      5     --critical-uptime='1'           CRITICAL: System uptime is: 38m 39s | 'uptime'=2319.00s;;0:1;0;
            ...      6     --check-overload                OK: System uptime is: 38m 39s | 'uptime'=2319.00s;;;0; 
            ...      7     --reboot-window                 OK: System uptime is: 38m 39s | 'uptime'=2319.00s;;;0;
            ...      8     --unit='h'                      OK: System uptime is: 38m 39s | 'uptime'=0.64h;;;0;
            ...      9     --unit='m'                      OK: System uptime is: 38m 39s | 'uptime'=38.65m;;;0;
            ...      10    --unit='s'                      OK: System uptime is: 38m 39s | 'uptime'=2319.00s;;;0;