*** Settings ***
Documentation       Cisco DNAC Sites

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
sites ${tc}
    [Tags]    cisco    api    dnac    sites
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=sites
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Site 'Centreon' devices: healthy 92.00% (484 on 527) - clients: healthy 0.00% (0 on 0) | 'Centreon#site.network.devices.healthy.count'=484;;;0;527 'Centreon#site.network.devices.healthy.percentage'=484.00;;;0;100 'Centreon#site.clients.healthy.count'=0;;;0;0 'Centreon#site.clients.healthy.percentage'=0.00;;;0;100
    ...    2
    ...    --filter-site-name='Centreon'
    ...    OK: Site 'Centreon' devices: healthy 92.00% (484 on 527) - clients: healthy 0.00% (0 on 0) | 'Centreon#site.network.devices.healthy.count'=484;;;0;527 'Centreon#site.network.devices.healthy.percentage'=484.00;;;0;100 'Centreon#site.clients.healthy.count'=0;;;0;0 'Centreon#site.clients.healthy.percentage'=0.00;;;0;100