*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::esx::plugin
...                 --mode=power
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000
...                 --esx-id=host-22


*** Test Cases ***
Power ${tc}
    [Tags]    apps    api    vmware    vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                    expected_result   --
        ...      1     ${EMPTY}                        UNKNOWN: no data for resource host-22 counter power.capacity.usage.HOST at the moment. - get_esx_stats function failed to retrieve stats The counter power.capacity.usage.HOST was not recorded for resource host-22 before. It will now (creating acq_spec).
        ...      2     ${EMPTY}                        OK: Power usage is 200 Watts | 'power.capacity.usage.watt'=200W;;;0;
        ...      3     --warning-usage-watt=0:0        WARNING: Power usage is 200 Watts | 'power.capacity.usage.watt'=200W;0:0;;0;
        ...      4     --critical-usage-watt=0:0       CRITICAL: Power usage is 200 Watts | 'power.capacity.usage.watt'=200W;;0:0;0;
