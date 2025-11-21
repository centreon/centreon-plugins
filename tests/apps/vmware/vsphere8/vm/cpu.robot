*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --mode=cpu
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --vm-id=vm-7722


*** Test Cases ***
Cpu ${tc}
    [Tags]    apps    api    vmware    vsphere8    vm
    ${command}    Catenate    ${CMD}    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                        expected_result   --
        ...      1     ${EMPTY}                                            UNKNOWN: no data for resource vm-7722 counter cpu.capacity.entitlement.VM at the moment. - get_vm_stats function failed to retrieve stats The counter cpu.capacity.entitlement.VM was not recorded for resource vm-7722 before. It will now (creating acq_spec). The counter cpu.capacity.usage.VM was not recorded for resource vm-7722 before. It will now (creating acq_spec).
        ...      2     ${EMPTY}                                            OK: CPU average usage is 11.13 %, used frequency is 81.56 kHz | 'cpu.capacity.usage.percentage'=11.13%;;;0;100 'cpu.capacity.usage.hertz'=81560000Hz;;;0;733000000
        ...      3     --warning-usage-prct=5                              WARNING: CPU average usage is 11.13 % | 'cpu.capacity.usage.percentage'=11.13%;0:5;;0;100 'cpu.capacity.usage.hertz'=81560000Hz;;;0;733000000
        ...      4     --critical-usage-prct=5                             CRITICAL: CPU average usage is 11.13 % | 'cpu.capacity.usage.percentage'=11.13%;;0:5;0;100 'cpu.capacity.usage.hertz'=81560000Hz;;;0;733000000
        ...      5     --warning-usage-frequency=5                         WARNING: used frequency is 81.56 kHz | 'cpu.capacity.usage.percentage'=11.13%;;;0;100 'cpu.capacity.usage.hertz'=81560000Hz;0:5;;0;733000000
        ...      6     --critical-usage-frequency=5                        CRITICAL: used frequency is 81.56 kHz | 'cpu.capacity.usage.percentage'=11.13%;;;0;100 'cpu.capacity.usage.hertz'=81560000Hz;;0:5;0;733000000
