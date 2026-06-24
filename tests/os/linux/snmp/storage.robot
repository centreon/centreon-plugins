*** Settings ***
Documentation       Check storage table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
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

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --filter-duplicate=''
    ...    OK: All storages are ok | 'count'=5;;;0; 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176
    ...    2
    ...    --filter-storage-type=''
    ...    OK: All storages are ok | 'count'=11;;;0; 'used_Physical memory'=1296941056B;;;0;2062598144 'used_Available memory'=0B;;;0;1143980032 'used_Virtual memory'=1296941056B;;;0;2062598144 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176 'used_Memory buffers'=37601280B;;;0;2062598144 'used_Cached memory'=523030528B;;;0;523030528 'used_Shared memory'=30310400B;;;0;30310400
    ...    3
    ...    --display-transform-dst='run'
    ...    OK: All storages are ok | 'count'=5;;;0; 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176
    ...    4
    ...    --filter-duplicate
    ...    OK: All storages are ok | 'count'=5;;;0; 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176
    ...    5
    ...    --filter-storage-type
    ...    OK: All storages are ok | 'count'=11;;;0; 'used_Physical memory'=1296941056B;;;0;2062598144 'used_Available memory'=0B;;;0;1143980032 'used_Virtual memory'=1296941056B;;;0;2062598144 'used_/run'=532480B;;;0;206262272 'used_/'=7394013184B;;;0;105088212992 'used_/dev/shm'=0B;;;0;1031299072 'used_/run/lock'=0B;;;0;5242880 'used_/run/user/0'=0B;;;0;206258176 'used_Memory buffers'=37601280B;;;0;2062598144 'used_Cached memory'=523030528B;;;0;523030528 'used_Shared memory'=30310400B;;;0;30310400

cgs-storage ${tc}
    [Tags]    os    linux    centreon-generic-snmp
    ${command}    Catenate
    ...    ${CENTREON_GENERIC_SNMP}
    ...    -j ${CURDIR}/generic-snmp/storage.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/linux
    ...    --filter-out='([mM]emory|Swap)'
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    All storages are OK | '/run#storage.usage.bytes'=532480B;;;0;206262272 '/#storage.usage.bytes'=7394013184B;;;0;105088212992 '/dev/shm#storage.usage.bytes'=0B;;;0;1031299072 '/run/lock#storage.usage.bytes'=0B;;;0;5242880 '/run/user/0#storage.usage.bytes'=0B;;;0;206258176 '/run#storage.usage.percent'=0.26%;;;0;100 '/#storage.usage.percent'=7.04%;;;0;100 '/dev/shm#storage.usage.percent'=0%;;;0;100 '/run/lock#storage.usage.percent'=0%;;;0;100 '/run/user/0#storage.usage.percent'=0%;;;0;100
    ...    2
    ...    --filter-in='^\/$'
    ...    All storages are OK | '/#storage.usage.bytes'=7394013184B;;;0;105088212992 '/#storage.usage.percent'=7.04%;;;0;100
    ...    3
    ...    --filter-in='^\/$' --warning-storage-bytes=1000
    ...    WARNING: '/#storage.usage.bytes' is 7394013184B | '/#storage.usage.bytes'=7394013184B;1000;;0;105088212992 '/#storage.usage.percent'=7.04%;;;0;100
    ...    4
    ...    --filter-in='^\/$' --critical-storage-bytes=1000
    ...    CRITICAL: '/#storage.usage.bytes' is 7394013184B | '/#storage.usage.bytes'=7394013184B;;1000;0;105088212992 '/#storage.usage.percent'=7.04%;;;0;100
    ...    5
    ...    --filter-in='^\/$' --warning-storage-prct=1
    ...    WARNING: '/#storage.usage.percent' is 7.04% | '/#storage.usage.bytes'=7394013184B;;;0;105088212992 '/#storage.usage.percent'=7.04%;1;;0;100
    ...    6
    ...    --filter-in='^\/$' --critical-storage-prct=1
    ...    CRITICAL: '/#storage.usage.percent' is 7.04% | '/#storage.usage.bytes'=7394013184B;;;0;105088212992 '/#storage.usage.percent'=7.04%;;1;0;100
