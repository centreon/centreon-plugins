*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s
Test Setup          Ctn Cleanup Cache

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
Memory with curl ${tc}
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                        expected_result   --
        ...      1     ${EMPTY}                                            OK: vms-usage-percentage : skipped (no value(s)), vms-usage-bytes : skipped (no value(s)) - no data for host host-22 counter mem.capacity.usable.HOST at the moment.
        ...      2     ${EMPTY}                                            OK: Memory used 39%, Memory used by VMs: 100.02 GB used - Usable: 253.97 GB | 'vms.memory.usage.percentage'=39.38%;;;0;100 'vms.memory.usage.bytes'=107400208056.32B;;;;272694090137.6
        ...      3     --warning-vms-usage-percentage=0:0                  WARNING: Memory used 39% | 'vms.memory.usage.percentage'=39.38%;0:0;;0;100 'vms.memory.usage.bytes'=107400208056.32B;;;;272694090137.6
        ...      4     --critical-vms-usage-percentage=0:0                 CRITICAL: Memory used 39% | 'vms.memory.usage.percentage'=39.38%;;0:0;0;100 'vms.memory.usage.bytes'=107400208056.32B;;;;272694090137.6
        ...      5     --warning-vms-usage-bytes=0:0                       WARNING: Memory used by VMs: 100.02 GB used - Usable: 253.97 GB | 'vms.memory.usage.percentage'=39.38%;;;0;100 'vms.memory.usage.bytes'=107400208056.32B;0:0;;;272694090137.6
        ...      6     --critical-vms-usage-bytes=0:0                      CRITICAL: Memory used by VMs: 100.02 GB used - Usable: 253.97 GB | 'vms.memory.usage.percentage'=39.38%;;;0;100 'vms.memory.usage.bytes'=107400208056.32B;;0:0;;272694090137.6

