*** Settings ***
Documentation       Check storage table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin


*** Test Cases ***
storage ${tc}
    [Tags]    os    linux
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=storage
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                       expected_result    --
            ...      1     --filter-duplicate=''               OK: All storages are ok | 'count'=5;;;0; 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176 
            ...      2     --filter-storage-type=''            OK: All storages are ok | 'count'=11;;;0; 'used_Physical memory'=1296941056B;;;0;2062598144 'used_Available memory'=0B;;;0;1143980032 'used_Virtual memory'=1296941056B;;;0;2062598144 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176 'used_Memory buffers'=37601280B;;;0;2062598144 'used_Cached memory'=523030528B;;;0;523030528 'used_Shared memory'=30310400B;;;0;30310400
            ...      3     --display-transform-dst='run'       OK: All storages are ok | 'count'=5;;;0; 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176
            ...      4     --filter-duplicate                  OK: All storages are ok | 'count'=5;;;0; 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176 
            ...      5     --filter-storage-type               OK: All storages are ok | 'count'=11;;;0; 'used_Physical memory'=1296941056B;;;0;2062598144 'used_Available memory'=0B;;;0;1143980032 'used_Virtual memory'=1296941056B;;;0;2062598144 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176 'used_Memory buffers'=37601280B;;;0;2062598144 'used_Cached memory'=523030528B;;;0;523030528 'used_Shared memory'=30310400B;;;0;30310400
