*** Settings ***
Documentation       apps::backup::veeam::vone::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}vone.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...         --plugin=apps::backup::veeam::vone::restapi::plugin
...         --mode=license
...         --hostname=${HOSTNAME}
...         --port=${APIPORT}
...         --proto=http
...         --api-username=UsErNaMe
...         --api-password=P@s$W0Rd


*** Test Cases ***
License ${tc}
    [Tags]    apps    backup    restapi
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
    ...    OK: license unit 'instances' total: 120 used: 132 (110.00%) free: 0 (0.00%) | 'instances#license.unit.usage.count'=132;;;0;120 'instances#license.unit.free.count'=0;;;0;120 'instances#license.unit.usage.percentage'=110.00%;;;0;100
    ...    2
    ...    --filter-counters=free
    ...    OK: license unit 'instances' | 'instances#license.unit.free.count'=0;;;0;120
    ...    3
    ...    --warning-license-unit-free=1:
    ...    WARNING: license unit 'instances' total: 120 used: 132 (110.00%) free: 0 (0.00%) | 'instances#license.unit.usage.count'=132;;;0;120 'instances#license.unit.free.count'=0;1:;;0;120 'instances#license.unit.usage.percentage'=110.00%;;;0;100
    ...    4
    ...    --critical-license-unit-free=1:
    ...    CRITICAL: license unit 'instances' total: 120 used: 132 (110.00%) free: 0 (0.00%) | 'instances#license.unit.usage.count'=132;;;0;120 'instances#license.unit.free.count'=0;;1:;0;120 'instances#license.unit.usage.percentage'=110.00%;;;0;100
    ...    5
    ...    --warning-license-unit-usage=:1
    ...    WARNING: license unit 'instances' total: 120 used: 132 (110.00%) free: 0 (0.00%) | 'instances#license.unit.usage.count'=132;0:1;;0;120 'instances#license.unit.free.count'=0;;;0;120 'instances#license.unit.usage.percentage'=110.00%;;;0;100
    ...    6
    ...    --critical-license-unit-usage=:1
    ...    CRITICAL: license unit 'instances' total: 120 used: 132 (110.00%) free: 0 (0.00%) | 'instances#license.unit.usage.count'=132;;0:1;0;120 'instances#license.unit.free.count'=0;;;0;120 'instances#license.unit.usage.percentage'=110.00%;;;0;100
    ...    7
    ...    --warning-license-unit-usage-prct=:1
    ...    WARNING: license unit 'instances' total: 120 used: 132 (110.00%) free: 0 (0.00%) | 'instances#license.unit.usage.count'=132;;;0;120 'instances#license.unit.free.count'=0;;;0;120 'instances#license.unit.usage.percentage'=110.00%;0:1;;0;100
    ...    8
    ...    --critical-license-unit-usage-prct=:1
    ...    CRITICAL: license unit 'instances' total: 120 used: 132 (110.00%) free: 0 (0.00%) | 'instances#license.unit.usage.count'=132;;;0;120 'instances#license.unit.free.count'=0;;;0;120 'instances#license.unit.usage.percentage'=110.00%;;0:1;0;100
