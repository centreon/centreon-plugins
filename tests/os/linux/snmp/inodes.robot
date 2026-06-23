*** Settings ***
Documentation       Check inodes table

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}          ${CENTREON_PLUGINS} --plugin=os::linux::snmp::plugin
${CGS_CMD}      ${CENTREON_PLUGIN_RUST_SNMP}


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

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --filter-path=''
    ...    OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
    ...    2
    ...    --display-transform-src='dev'
    ...    OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_//shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
    ...    3
    ...    --display-transform-dst='run'
    ...    OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
    ...    4
    ...    --filter-device
    ...    OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100
    ...    5
    ...    --filter-path
    ...    OK: All inode partitions are ok | 'used_/'=6%;;;0;100 'used_/dev/shm'=0%;;;0;100 'used_/run'=0%;;;0;100 'used_/run/lock'=0%;;;0;100 'used_/run/user/0'=0%;;;0;100

cgs-inodes ${tc}
    [Tags]    os    linux    centreon-plugin-rust-snmp
    ${command}    Catenate
    ...    ${CGS_CMD}
    ...    -j ${CURDIR}/generic-snmp/inodes.json
    ...    --hostname=${HOSTNAME}
    ...    --port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=os/linux/snmp/linux
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    All inode partitions are OK | '/run#inodes.usage.percent'=0%;;;0;100 '/#inodes.usage.percent'=6%;;;0;100 '/dev/shm#inodes.usage.percent'=0%;;;0;100 '/run/lock#inodes.usage.percent'=0%;;;0;100 '/run/user/0#inodes.usage.percent'=0%;;;0;100
    ...    2
    ...    --check-format
    ...    Check format of JSON file '${CURDIR}/generic-snmp/inodes.json' JSON is valid
    ...    3
    ...    --warning-inodes=1
    ...    WARNING: '/#inodes.usage.percent' is 6% | '/run#inodes.usage.percent'=0%;1;;0;100 '/#inodes.usage.percent'=6%;1;;0;100 '/dev/shm#inodes.usage.percent'=0%;1;;0;100 '/run/lock#inodes.usage.percent'=0%;1;;0;100 '/run/user/0#inodes.usage.percent'=0%;1;;0;100
    ...    4
    ...    --critical-inodes=1
    ...    CRITICAL: '/#inodes.usage.percent' is 6% | '/run#inodes.usage.percent'=0%;;1;0;100 '/#inodes.usage.percent'=6%;;1;0;100 '/dev/shm#inodes.usage.percent'=0%;;1;0;100 '/run/lock#inodes.usage.percent'=0%;;1;0;100 '/run/user/0#inodes.usage.percent'=0%;;1;0;100
