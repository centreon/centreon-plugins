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
Discovery ${tc}
    [Tags]    storage     api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode discovery
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                          expected_regexp    --
            ...      1        ${EMPTY}                                              "discovered_items":3
            ...      2        --resource-type=vm                                    (?=.*"ip_addresses":\\\\["123.321.123.321","127.0.0.1"\\\\])(?=.*"os_info_name":"XxXxXx GNU/Linux")
            ...      3        --resource-type=node                                  ^(?!.*(ip_addresses|os_info_name)).*$


VmUsage ${tc}
    [Tags]    storage     api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode vm-usage
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                          expected_regexp    --
            ...      1        ${EMPTY}                                              OK: All vms are ok | 'node/www1#vm.memory.usage.bytes'=524288B;;;0;1048576 'node/www1#vm.read.usage.iops'=0.00iops;;;0; 'node/www1#vm.write.usage.iops'=0.00iops;;;0; 'node/www1#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'node/www1#vm.traffic.out.bitspersecond'=0.00b/s;;;0; 'qemu/101#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/101#vm.read.usage.iops'=0.00iops;;;0; 'qemu/101#vm.write.usage.iops'=0.00iops;;;0; 'qemu/101#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'qemu/101#vm.traffic.out.bitspersecond'=0.00b/s;;;0; 'storage/local#vm.memory.usage.bytes'=524288B;;;0;1048576 'storage/local#vm.read.usage.iops'=0.00iops;;;0; 'storage/local#vm.write.usage.iops'=0.00iops;;;0; 'storage/local#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'storage/local#vm.traffic.out.bitspersecond'=0.00b/s;;;0;
            ...      2        --filter-name=XxXxX                                   OK: VM 'node/www1' state : online, memory total: 1.00 MB used: 512.00 KB (50.00%) free: 512.00 KB (50.00%), read-iops : Buffer creation, write-iops : Buffer creation, traffic-in : Buffer creation, traffic-out : Buffer creation | 'node/www1#vm.memory.usage.bytes'=524288B;;;0;1048576
            ...      3        --include-node-name=ddddd                             OK: VM 'qemu/101' state : running, memory total: 1.00 MB used: 512.00 KB (50.00%) free: 512.00 KB (50.00%), read-iops : Buffer creation, write-iops : Buffer creation, traffic-in : Buffer creation, traffic-out : Buffer creation | 'qemu/101#vm.memory.usage.bytes'=524288B;;;0;1048576
            ...      4        --include-node-name=RR --exclude-node-name=RR         UNKNOWN: No vm found.
            ...      5        --exclude-name=www                                    OK: All vms are ok | 'node/www1#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/101#vm.memory.usage.bytes'=524288B;;;0;1048576 'storage/local#vm.memory.usage.bytes'=524288B;;;0;1048576
            ...      6        --exclude-node-name=cccc                              OK: All vms are ok | 'node/www1#vm.memory.usage.bytes'=524288B;;;0;1048576 'node/www1#vm.read.usage.iops'=0.00iops;;;0; 'node/www1#vm.write.usage.iops'=0.00iops;;;0; 'node/www1#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'node/www1#vm.traffic.out.bitspersecond'=0.00b/s;;;0; 'qemu/101#vm.memory.usage.bytes'=524288B;;;0;1048576 'qemu/101#vm.read.usage.iops'=0.00iops;;;0; 'qemu/101#vm.write.usage.iops'=0.00iops;;;0; 'qemu/101#vm.traffic.in.bitspersecond'=0.00b/s;;;0; 'qemu/101#vm.traffic.out.bitspersecond'=0.00b/s;;;0;
