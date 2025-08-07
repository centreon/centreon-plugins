*** Settings ***
Documentation       Check memory usages.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Test Setup          Ctn Generic Suite Setup

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cyberoam::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    network    cyberoam
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cyberoam/snmp/slim_sophos
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                                                  expected_result    --
            ...      1     ${EMPTY}                                                                                       OK: Physical memory Total: 7.61 GB Used: 4.41 GB (58.00%) Free: 3.20 GB (42.00%) - Swap memory Total: 7.73 GB Used: 791.10 MB (10.00%) Free: 6.95 GB (90.00%) | 'physical_used'=4738284257.28B;;;0;8169455616 'swap_used'=829528473.6B;;;0;8295284736
            ...      2     --filter-counters='^physical-usage$'                                                           OK: Physical memory Total: 7.61 GB Used: 4.41 GB (58.00%) Free: 3.20 GB (42.00%) | 'physical_used'=4738284257.28B;;;0;8169455616                           
            ...      3     --warning-physical-usage=40 --critical-physical-usage=60                                       WARNING: Physical memory Total: 7.61 GB Used: 4.41 GB (58.00%) Free: 3.20 GB (42.00%) | 'physical_used'=4738284257.28B;0:3267782246;0:4901673369;0;8169455616 'swap_used'=829528473.6B;;;0;8295284736
            ...      4     --warning-swap-usage=100 --critical-swap-usage=0                                               CRITICAL: Swap memory Total: 7.73 GB Used: 791.10 MB (10.00%) Free: 6.95 GB (90.00%) | 'physical_used'=4738284257.28B;;;0;8169455616 'swap_used'=829528473.6B;0:8295284736;0:0;0;8295284736
            ...      5     --warning-physical-usage=60 --critical-physical-usage=40                                       CRITICAL: Physical memory Total: 7.61 GB Used: 4.41 GB (58.00%) Free: 3.20 GB (42.00%) | 'physical_used'=4738284257.28B;0:4901673369;0:3267782246;0;8169455616 'swap_used'=829528473.6B;;;0;8295284736
            ...      6     --warning-swap-usage=0 --critical-swap-usage=100                                               WARNING: Swap memory Total: 7.73 GB Used: 791.10 MB (10.00%) Free: 6.95 GB (90.00%) | 'physical_used'=4738284257.28B;;;0;8169455616 'swap_used'=829528473.6B;0:0;0:8295284736;0;8295284736