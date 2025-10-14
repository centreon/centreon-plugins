*** Settings ***


Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin
...                 --mode=power
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000

*** Test Cases ***
Power ${tc}
    [Tags]    apps    api    vmware   vsphere8    vm
    ${command}    Catenate    ${CMD} --http-backend=curl ${filter_option} ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    filter_option                extraoptions                    expected_result   --
        ...      1     --vm-id=vm-1234              ${EMPTY}                        UNKNOWN: no data for resource vm-1234 counter power.capacity.usage.VM at the moment. - No available data The counter power.capacity.usage.VM was not recorded for resource vm-1234 before. It will now (creating acq_spec).
        ...      2     --vm-id=vm-1234              ${EMPTY}                        OK: Power usage is 13.5 Watts | 'power.capacity.usage.watt'=13.5W;;;0;
        ...      3     --vm-id=vm-1234              --warning-usage-watt=0:0        WARNING: Power usage is 13.5 Watts | 'power.capacity.usage.watt'=13.5W;0:0;;0;
        ...      4     --vm-id=vm-1234              --critical-usage-watt=0:0       CRITICAL: Power usage is 13.5 Watts | 'power.capacity.usage.watt'=13.5W;;0:0;0;
        ...      5     --vm-name=web-server-02      ${EMPTY}                        OK: Power usage is 13.5 Watts | 'power.capacity.usage.watt'=13.5W;;;0;
        ...      6     --vm-name=web-server-02      --warning-usage-watt=0:0        WARNING: Power usage is 13.5 Watts | 'power.capacity.usage.watt'=13.5W;0:0;;0;
        ...      7     --vm-name=web-server-02      --critical-usage-watt=0:0       CRITICAL: Power usage is 13.5 Watts | 'power.capacity.usage.watt'=13.5W;;0:0;0;
        ...      8     --vm-name=web-server-05      --critical-usage-watt=0:0       UNKNOWN: get_vm_stats method cannot get vm ID from vm name
        ...      9     --vm-id=vm-9876              --critical-usage-watt=0:0       UNKNOWN: no data for resource vm-9876 counter power.capacity.usage.VM at the moment. - No available data The counter power.capacity.usage.VM was not recorded for resource vm-9876 before. It will now (creating acq_spec).

