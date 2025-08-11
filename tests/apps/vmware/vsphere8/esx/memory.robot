*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vmware8-restapi.mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --mode=memory
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --esx-id=host-22

*** Test Cases ***
Memory ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:    tc    extraoptions                                        expected_result   --
        ...      1     ${EMPTY}                                            OK: usage-prct : skipped (no value(s)) - usage-bytes : skipped (no value(s)) - no data for host host-22 counter mem.capacity.usable.HOST at the moment.
        ...      2     ${EMPTY}                                            OK: 39% of usable memory is used by VMs - Memory used: 100.02 GB used - Usable: 253.97 GB | 'vms.memory.usage.percentage'=39.38%;;;0;100 'vms.memory.usage.bytes'=107400208056B;;;;272694090137
        ...      3     --warning-usage-prct=0:0                  WARNING: 39% of usable memory is used by VMs | 'vms.memory.usage.percentage'=39.38%;0:0;;0;100 'vms.memory.usage.bytes'=107400208056B;;;;272694090137
        ...      4     --critical-usage-prct=0:0                 CRITICAL: 39% of usable memory is used by VMs | 'vms.memory.usage.percentage'=39.38%;;0:0;0;100 'vms.memory.usage.bytes'=107400208056B;;;;272694090137
        ...      5     --warning-usage-bytes=0:0                       WARNING: Memory used: 100.02 GB used - Usable: 253.97 GB | 'vms.memory.usage.percentage'=39.38%;;;0;100 'vms.memory.usage.bytes'=107400208056B;0:0;;;272694090137
        ...      6     --critical-usage-bytes=0:0                      CRITICAL: Memory used: 100.02 GB used - Usable: 253.97 GB | 'vms.memory.usage.percentage'=39.38%;;;0;100 'vms.memory.usage.bytes'=107400208056B;;0:0;;272694090137
