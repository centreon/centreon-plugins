*** Settings ***
Documentation       Linux Local Systemd-sc-status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
storage ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=storage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/windows_anon
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                                    expected_result    --
            ...      1     --space-reservation=90                                                                           OK: All storages are ok | 'count'=7;;;0; 'used_/dev/shm'=0B;;;0;2014359552 'used_/run'=8835072B;;;0;2014359552 'used_/sys/fs/cgroup'=0B;;;0;2014359552 'used_/'=2606518272B;;;0;31989936128 'used_/boot'=104706048B;;;0;1063256064 'used_/boot/efi'=6103040B;;;0;209489920 'used_/run/user/1000'=0B;;;0;402870272
            ...      2     --filter-duplicate=''                                                                            OK: All storages are ok | 'count'=6;;;0; 'used_/dev/shm'=0B;;;0;2014359552 'used_/run'=8835072B;;;0;2014359552 'used_/'=2606518272B;;;0;31989936128 'used_/boot'=104706048B;;;0;1063256064 'used_/boot/efi'=6103040B;;;0;209489920 'used_/run/user/1000'=0B;;;0;402870272
            ...      3     --filter-storage-type='^(hrStorageFixedDisk|hrStorageNetworkDisk|hrFSBerkeleyFFS)$'              OK: All storages are ok | 'count'=7;;;0; 'used_/dev/shm'=0B;;;0;2014359552 'used_/run'=8835072B;;;0;2014359552 'used_/sys/fs/cgroup'=0B;;;0;2014359552 'used_/'=2606518272B;;;0;31989936128 'used_/boot'=104706048B;;;0;1063256064 'used_/boot/efi'=6103040B;;;0;209489920 'used_/run/user/1000'=0B;;;0;402870272
