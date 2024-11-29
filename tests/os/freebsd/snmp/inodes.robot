*** Settings ***
Documentation       Check inodes table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::freebsd::snmp::plugin


*** Test Cases ***
inodes ${tc}
    [Tags]    os    freebsd
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=inodes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/freebsd/snmp/freebsd
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                       expected_result    --
            ...      1     --filter-path=''                    OK: All inode partitions are ok | 'used_/'=0%;;;0;100 'used_/dev'=100%;;;0;100 'used_/tmp'=0%;;;0;100 'used_/var'=0%;;;0;100 'used_/var/dhcpd/dev'=100%;;;0;100 'used_/var/run'=4%;;;0;100 'used_/zroot'=0%;;;0;100
            ...      2     --display-transform-src='dev'       OK: All inode partitions are ok | 'used_/'=0%;;;0;100 'used_/tmp'=0%;;;0;100 'used_/var'=0%;;;0;100 'used_/var/dhcpd/'=100%;;;0;100 'used_/var/run'=4%;;;0;100 'used_/zroot'=0%;;;0;100
            ...      3     --display-transform-dst='run'       OK: All inode partitions are ok | 'used_/'=0%;;;0;100 'used_/dev'=100%;;;0;100 'used_/tmp'=0%;;;0;100 'used_/var'=0%;;;0;100 'used_/var/dhcpd/dev'=100%;;;0;100 'used_/var/run'=4%;;;0;100 'used_/zroot'=0%;;;0;100
            ...      4     --filter-device                     OK: All inode partitions are ok | 'used_/'=0%;;;0;100 'used_/dev'=100%;;;0;100 'used_/tmp'=0%;;;0;100 'used_/var'=0%;;;0;100 'used_/var/dhcpd/dev'=100%;;;0;100 'used_/var/run'=4%;;;0;100 'used_/zroot'=0%;;;0;100
            ...      5     --filter-path                       OK: All inode partitions are ok | 'used_/'=0%;;;0;100 'used_/dev'=100%;;;0;100 'used_/tmp'=0%;;;0;100 'used_/var'=0%;;;0;100 'used_/var/dhcpd/dev'=100%;;;0;100 'used_/var/run'=4%;;;0;100 'used_/zroot'=0%;;;0;100
