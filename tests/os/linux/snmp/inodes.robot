*** Settings ***
Documentation       Check inodes table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
inodes ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=inodes
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                       expected_result    --
            ...      1     --filter-path=''                    OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
            ...      2     --display-transform-src='dev'       OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_//shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
            ...      3     --display-transform-dst='run'       OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
            ...      4     --filter-device                     OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100 
            ...      5     --filter-path                       OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
