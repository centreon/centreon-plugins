*** Settings ***
Documentation       Check swap table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::freebsd::snmp::plugin


*** Test Cases ***
swap ${tc}
    [Tags]    os    freebsd
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=swap
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/freebsd/snmp/freebsd
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                       expected_result    --
            ...      1     ${EMPTY}                            OK: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'used'=0B;;;0;2147352576 'free'=2147352576B;;;0;2147352576 'used_prct'=0.00%;;;0;100
            ...      2     --no-swap                           OK: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'used'=0B;;;0;2147352576 'free'=2147352576B;;;0;2147352576 'used_prct'=0.00%;;;0;100
            ...      3     --warning-usage='-2:-1'             WARNING: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'used'=0B;-2:-1;;0;2147352576 'free'=2147352576B;;;0;2147352576 'used_prct'=0.00%;;;0;100
            ...      4     --critical-usage='-2:-1'            CRITICAL: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'used'=0B;;-2:-1;0;2147352576 'free'=2147352576B;;;0;2147352576 'used_prct'=0.00%;;;0;100  
            ...      5     --warning-usage-free='1'            WARNING: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'used'=0B;;;0;2147352576 'free'=2147352576B;0:1;;0;2147352576 'used_prct'=0.00%;;;0;100
            ...      6     --critical-usage-free='1'           CRITICAL: Swap Total: 2.00 GB Used: 0.00 B (0.00%) Free: 2.00 GB (100.00%) | 'used'=0B;;;0;2147352576 'free'=2147352576B;;0:1;0;2147352576 'used_prct'=0.00%;;;0;100
            ...      7     --warning-usage-prct='-2:-1'        WARNING: Used : 0.00 % | 'used'=0B;;;0;2147352576 'free'=2147352576B;;;0;2147352576 'used_prct'=0.00%;-2:-1;;0;100
            ...      8     --critical-usage-prct='-2:-1'       CRITICAL: Used : 0.00 % | 'used'=0B;;;0;2147352576 'free'=2147352576B;;;0;2147352576 'used_prct'=0.00%;;-2:-1;0;100              
