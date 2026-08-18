*** Settings ***
Documentation       HP OneView Restapi Hardware plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hp_oneview.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=hardware::server::hp::oneview::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=toto
...                 --api-password=toto
...                 --mode=hardware


*** Test Cases ***
Hardware ${tc}
    [Tags]    hardware    server    hp    oneview    api    mockoon
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    CRITICAL: Enclosure '09USE62519F1' status is 'Critical' - Enclosure fan '09USE62519F1:1' status is 'Critical' - Server 'cent1.centreon.com.com' status is 'Critical' - Server 'cent2.centreon.com' status is 'Critical' - Server 'cent3' status is 'Critical' - Server 'cent4' status is 'Critical' WARNING: Enclosure '09USE62519EF' status is 'Warning' - Enclosure fan '09USE62519EF:1' status is 'Warning' | 'hardware.enclosure.count'=4;;;; 'hardware.server.count'=4;;;;
    ...    2
    ...    --component='enclosure'
    ...    CRITICAL: Enclosure '09USE62519F1' status is 'Critical' - Enclosure fan '09USE62519F1:1' status is 'Critical' WARNING: Enclosure '09USE62519EF' status is 'Warning' - Enclosure fan '09USE62519EF:1' status is 'Warning' | 'hardware.enclosure.count'=4;;;;
    ...    3
    ...    --component='server'
    ...    CRITICAL: Server 'cent1.centreon.com.com' status is 'Critical' - Server 'cent2.centreon.com' status is 'Critical' - Server 'cent3' status is 'Critical' - Server 'cent4' status is 'Critical' | 'hardware.server.count'=4;;;;
    ...    4
    ...    --component='server' --filter='server,cent4'
    ...    CRITICAL: Server 'cent1.centreon.com.com' status is 'Critical' - Server 'cent2.centreon.com' status is 'Critical' - Server 'cent3' status is 'Critical' | 'hardware.server.count'=3;;;;
    ...    5
    ...    --component='server' --threshold-overload='server,OK,critical'
    ...    OK: All 4 components are ok [4/4 server]. | 'hardware.server.count'=4;;;;
    ...    6
    ...    --component='enclosure' --filter='enclosure,09USE62519F1'
    ...    WARNING: Enclosure '09USE62519EF' status is 'Warning' - Enclosure fan '09USE62519EF:1' status is 'Warning' | 'hardware.enclosure.count'=3;;;;
