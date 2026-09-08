*** Settings ***
Documentation       Cisco DNAC Devices

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Setup          CTN Cleanup Cache
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}cisco_dnac.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::cisco::dnac::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=centreon
...                 --api-password=centreon


*** Test Cases ***
devices ${tc}
    [Tags]    cisco    api    dnac    devices
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=network-devices
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All network categories are ok | 'network.devices.total.count'=527;;;0; 'Centreon1#category.network.devices.health.good.count'=43;;;0;43 'Centreon1#category.network.devices.health.good.percentage'=100.00;;;0;100 'Centreon1#category.network.devices.health.fair.count'=0;;;0;43 'Centreon1#category.network.devices.health.fair.percentage'=0.00;;;0;100 'Centreon1#category.network.devices.health.bad.count'=0;;;0;43 'Centreon1#category.network.devices.health.bad.percentage'=0.00;;;0;100 'Centreon2#category.network.devices.health.good.count'=4;;;0;5 'Centreon2#category.network.devices.health.good.percentage'=80.00;;;0;100 'Centreon2#category.network.devices.health.fair.count'=0;;;0;5 'Centreon2#category.network.devices.health.fair.percentage'=0.00;;;0;100 'Centreon2#category.network.devices.health.bad.count'=0;;;0;5 'Centreon2#category.network.devices.health.bad.percentage'=0.00;;;0;100 'Centreon3#category.network.devices.health.good.count'=2;;;0;2 'Centreon3#category.network.devices.health.good.percentage'=100.00;;;0;100 'Centreon3#category.network.devices.health.fair.count'=0;;;0;2 'Centreon3#category.network.devices.health.fair.percentage'=0.00;;;0;100 'Centreon3#category.network.devices.health.bad.count'=0;;;0;2 'Centreon3#category.network.devices.health.bad.percentage'=0.00;;;0;100 'Centreon4#category.network.devices.health.good.count'=437;;;0;477 'Centreon4#category.network.devices.health.good.percentage'=91.61;;;0;100 'Centreon4#category.network.devices.health.fair.count'=21;;;0;477 'Centreon4#category.network.devices.health.fair.percentage'=4.40;;;0;100 'Centreon4#category.network.devices.health.bad.count'=0;;;0;477 'Centreon4#category.network.devices.health.bad.percentage'=0.00;;;0;100
    ...    2
    ...    --filter-category-name='Centreon1'
    ...    OK: Network category 'Centreon1' good devices: 100.00% (43 on 43) - fair devices: 0.00% (0 on 43) - bad devices: 0.00% (0 on 43) | 'network.devices.total.count'=43;;;0; 'Centreon1#category.network.devices.health.good.count'=43;;;0;43 'Centreon1#category.network.devices.health.good.percentage'=100.00;;;0;100 'Centreon1#category.network.devices.health.fair.count'=0;;;0;43 'Centreon1#category.network.devices.health.fair.percentage'=0.00;;;0;100 'Centreon1#category.network.devices.health.bad.count'=0;;;0;43 'Centreon1#category.network.devices.health.bad.percentage'=0.00;;;0;100