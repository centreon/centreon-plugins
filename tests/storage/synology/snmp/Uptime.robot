*** Settings ***
Documentation       Storage Synology SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                          ${CENTREON_PLUGINS} --plugin=storage::synology::snmp::plugin

*** Test Cases ***
Uptime ${tc}
    [Tags]    storage    synology    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=uptime
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/synology/snmp/synology-disk-ok
    ...    --warning-uptime=${warning}
    ...    --critical-uptime=${critical}
            
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc   warning                critical                   expected_result    --
            ...      1    ${Empty}               ${Empty}                   OK: System uptime is: 46m 5s | 'uptime'=2765.00s;;;0;
            ...      2    10                     ${Empty}                   WARNING: System uptime is: 46m 5s | 'uptime'=2765.00s;0:10;;0;
            ...      3    ${Empty}               10                         CRITICAL: System uptime is: 46m 5s | 'uptime'=2765.00s;;0:10;0;