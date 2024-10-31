*** Settings ***
Documentation       Check memory usage (AIRESPACE-SWITCHING-MIB).

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::wlc::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    network    wlc    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/wlc/snmp/slim_cisco_wlc
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --warning-usage=100 --critical-usage=0                                CRITICAL: Ram total: 695.16 MB used: 343.21 MB (49.37%) free: 351.95 MB (50.63%) | 'memory.usage.bytes'=359882752B;0:100;0:0;0;728924160 'memory.free.bytes'=369041408B;;;0;728924160 'memory.usage.percentage'=49.37%;;;0;100
            ...      2     --warning-usage=0 --critical-usage=100                                CRITICAL: Ram total: 695.16 MB used: 343.21 MB (49.37%) free: 351.95 MB (50.63%) | 'memory.usage.bytes'=359882752B;0:0;0:100;0;728924160 'memory.free.bytes'=369041408B;;;0;728924160 'memory.usage.percentage'=49.37%;;;0;100
            ...      3     --warning-usage-free=50 --critical-usage-free=50                      CRITICAL: Ram total: 695.16 MB used: 343.21 MB (49.37%) free: 351.95 MB (50.63%) | 'memory.usage.bytes'=359882752B;;;0;728924160 'memory.free.bytes'=369041408B;0:50;0:50;0;728924160 'memory.usage.percentage'=49.37%;;;0;100
            ...      4     --warning-usage-prct=100 --critical-usage-prct=0                      CRITICAL: Ram used: 49.37 % | 'memory.usage.bytes'=359882752B;;;0;728924160 'memory.free.bytes'=369041408B;;;0;728924160 'memory.usage.percentage'=49.37%;0:100;0:0;0;100
            ...      5     --verbose                                                             OK: Ram total: 695.16 MB used: 343.21 MB (49.37%) free: 351.95 MB (50.63%) | 'memory.usage.bytes'=359882752B;;;0;728924160 'memory.free.bytes'=369041408B;;;0;728924160 'memory.usage.percentage'=49.37%;;;0;100