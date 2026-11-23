*** Settings ***
Documentation       Proxmox VE REST API Mode Discovery

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}proxmox.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::proxmox::ve::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
VmUsage ${tc}
    [Tags]    storage    api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode vm-usage
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_regexp
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All vms are ok | 'qemu/100000#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100001#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100002#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100003#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100004#vm.memory.usage.bytes'=524288B;;;0;1048576
    ...    2
    ...    --include-name=CENTREON01
    ...    OK: VM 'qemu/100000' state : running, memory total: 1.00 MB used: 512.00 KB (50.00%) free: 512.00 KB (50.00%), read-iops : Buffer creation, write-iops : Buffer creation, traffic-in : Buffer creation, traffic-out : Buffer creation | 'qemu/100000#vm.memory.usage.bytes'=524288B;;;0;1048576
    ...    3
    ...    --include-node-name=centreon02-pm04
    ...    OK: All vms are ok | 'qemu/100003#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100004#vm.memory.usage.bytes'=524288B;;;0;1048576
    ...    4
    ...    --include-node-name=centreon02-pm04 --exclude-node-name=centreon02-pm04
    ...    UNKNOWN: No vm found.
    ...    5
    ...    --exclude-name=CENTREON01
    ...    OK: All vms are ok | 'qemu/100001#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100002#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100003#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100004#vm.memory.usage.bytes'=524288B;;;0;1048576
    ...    6
    ...    --exclude-node-name=centreon02-pm04
    ...    OK: All vms are ok | 'qemu/100000#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100000#vm.read.usage.iops'=0.00iops;;;0; 'qemu/100000#vm.write.usage.iops'=0.00iops;;;0; 'qemu/100000#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'qemu/100000#vm.traffic.out.bitspersecond'=0.00b/s;;;0; 'qemu/100001#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100001#vm.read.usage.iops'=0.00iops;;;0; 'qemu/100001#vm.write.usage.iops'=0.00iops;;;0; 'qemu/100001#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'qemu/100001#vm.traffic.out.bitspersecond'=0.00b/s;;;0; 'qemu/100002#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100002#vm.read.usage.iops'=0.00iops;;;0; 'qemu/100002#vm.write.usage.iops'=0.00iops;;;0; 'qemu/100002#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'qemu/100002#vm.traffic.out.bitspersecond'=0.00b/s;;;0;
    ...    7
    ...    --include-tags=rust
    ...    OK: VM 'qemu/100000' state : running, memory total: 1.00 MB used: 512.00 KB (50.00%) free: 512.00 KB (50.00%), read-iops : Buffer creation, write-iops : Buffer creation, traffic-in : Buffer creation, traffic-out : Buffer creation | 'qemu/100000#vm.memory.usage.bytes'=524288B;;;0;1048576
    ...    8
    ...    --include-tags=linux
    ...    UNKNOWN: No vm found.
    ...    9
    ...    --exclude-tags=rust
    ...    OK: All vms are ok | 'qemu/100001#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100002#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100003#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/100004#vm.memory.usage.bytes'=524288B;;;0;1048576
    ...    10
    ...    --include-tags=nonexistent
    ...    UNKNOWN: No vm found.
