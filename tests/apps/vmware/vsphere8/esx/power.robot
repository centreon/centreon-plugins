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
    [Tags]    apps    api    vmware   vsphere8    esx
    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                    expected_result   --
        ...      1     ${EMPTY}                        OK: usage-watts : skipped (no value(s)) - no data for resource host-22 counter power.capacity.usage.HOST at the moment.
        ...      2     ${EMPTY}                        OK: Power usage is 200 Watts | 'power.capacity.usage.watts'=200W;;;0;
        ...      3     --warning-usage-watts=0:0       WARNING: Power usage is 200 Watts | 'power.capacity.usage.watts'=200W;0:0;;0;
        ...      4     --critical-usage-watts=0:0      CRITICAL: Power usage is 200 Watts | 'power.capacity.usage.watts'=200W;;0:0;0;
