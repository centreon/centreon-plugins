*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --mode=memory
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --vm-id=host-22

*** Test Cases ***
Memory ${tc}
    [Tags]    apps    api    vmware   vsphere8    vm
    ${command}    Catenate    ${CMD}    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                       expected_result   --
        ...      1     ${EMPTY}                           OK: usage-prct : skipped (no value(s)) - usage-bytes : skipped (no value(s)) - no data for host host-22 counter mem.capacity.entitlement.VM at the moment.
        ...      2     ${EMPTY}                           OK: 17% of usable memory is used by VMs - Memory used: 285.55 MB used - Usable: 1.60 GB | 'vms.memory.usage.percentage'=17.41%;;;0;100 'vms.memory.usage.bytes'=299420876B;;;;1720126013
        ...      3     --warning-usage-prct=0:0           WARNING: 17% of usable memory is used by VMs | 'vms.memory.usage.percentage'=17.41%;0:0;;0;100 'vms.memory.usage.bytes'=299420876B;;;;1720126013
        ...      4     --critical-usage-prct=0:0          CRITICAL: 17% of usable memory is used by VMs | 'vms.memory.usage.percentage'=17.41%;;0:0;0;100 'vms.memory.usage.bytes'=299420876B;;;;1720126013
        ...      5     --warning-usage-bytes=0:0          WARNING: Memory used: 285.55 MB used - Usable: 1.60 GB | 'vms.memory.usage.percentage'=17.41%;;;0;100 'vms.memory.usage.bytes'=299420876B;0:0;;;1720126013
        ...      6     --critical-usage-bytes=0:0         CRITICAL: Memory used: 285.55 MB used - Usable: 1.60 GB | 'vms.memory.usage.percentage'=17.41%;;;0;100 'vms.memory.usage.bytes'=299420876B;;0:0;;1720126013
