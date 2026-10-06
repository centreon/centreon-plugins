*** Settings ***
Documentation     apps::backup::veeam::vbr::restapi::plugin

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}veeam-vbr.mockoon.json

${CMD}             ${CENTREON_PLUGINS}
...                --plugin=apps::backup::veeam::vbr::restapi::plugin
...                --mode=licenses
...                --http-peer-addr=${HOSTNAME}
...                --port=${APIPORT}
...                --proto=http
...                --api-username=username
...                --api-password=password


*** Test Cases ***
Licenses ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=${hostname}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    hostname
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    perpetual.example.com
    ...    ${EMPTY}
    ...    OK: License 'Example Company' [type: Perpetual] [edition: EnterprisePlus] status: Valid, instances total: 100 used: 4 (4.00%) free: 96 (96.00%) | 'license.instances.usage.count'=4;;;0;100 'license.instances.free.count'=96;;;0;100 'license.instances.usage.percentage'=4.00%;;;0;100
    ...    2
    ...    perpetual.example.com
    ...    --warning-license-instances-usage=:2
    ...    WARNING: License 'Example Company' [type: Perpetual] [edition: EnterprisePlus] instances total: 100 used: 4 (4.00%) free: 96 (96.00%) | 'license.instances.usage.count'=4;0:2;;0;100 'license.instances.free.count'=96;;;0;100 'license.instances.usage.percentage'=4.00%;;;0;100
    ...    3
    ...    perpetual.example.com
    ...    --critical-license-instances-free=100:
    ...    CRITICAL: License 'Example Company' [type: Perpetual] [edition: EnterprisePlus] instances total: 100 used: 4 (4.00%) free: 96 (96.00%) | 'license.instances.usage.count'=4;;;0;100 'license.instances.free.count'=96;;100:;0;100 'license.instances.usage.percentage'=4.00%;;;0;100
    ...    4
    ...    perpetual.example.com
    ...    --warning-license-instances-usage-prct=:3
    ...    WARNING: License 'Example Company' [type: Perpetual] [edition: EnterprisePlus] instances total: 100 used: 4 (4.00%) free: 96 (96.00%) | 'license.instances.usage.count'=4;;;0;100 'license.instances.free.count'=96;;;0;100 'license.instances.usage.percentage'=4.00%;0:3;;0;100
    ...    5
    ...    perpetual.example.com
    ...    --warning-status='\\\%{type} eq "Perpetual"'
    ...    WARNING: License 'Example Company' [type: Perpetual] [edition: EnterprisePlus] status: Valid | 'license.instances.usage.count'=4;;;0;100 'license.instances.free.count'=96;;;0;100 'license.instances.usage.percentage'=4.00%;;;0;100
    ...    6
    ...    expired.example.com
    ...    ${EMPTY}
    ...    CRITICAL: License 'Example Company' [type: Subscription] [edition: Standard] status: Expired | 'license.expires.days'=0d;;;0; 'license.instances.usage.count'=12;;;0;10 'license.instances.free.count'=0;;;0;10 'license.instances.usage.percentage'=120.00%;;;0;100
    ...    7
    ...    expired.example.com
    ...    --critical-status='' --warning-expires=1:
    ...    WARNING: License 'Example Company' [type: Subscription] [edition: Standard] expires in 0s | 'license.expires.days'=0d;1:;;0; 'license.instances.usage.count'=12;;;0;10 'license.instances.free.count'=0;;;0;10 'license.instances.usage.percentage'=120.00%;;;0;100
    ...    8
    ...    invalid-json.example.com
    ...    ${EMPTY}
    ...    UNKNOWN: Cannot decode response (add --debug option to display returned content)
    ...    9
    ...    unauthorized.example.com
    ...    ${EMPTY}
    ...    UNKNOWN: 401 Unauthorized
    ...    10
    ...    api-version.example.com
    ...    --api-version=0.9
    ...    UNKNOWN: 400 Bad Request

Licenses expiration ${tc}
    [Tags]    apps    backup    veeam    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --hostname=valid.example.com
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    ^OK: License 'Example Company' \\\\[type: Subscription\\\\] \\\\[edition: EnterprisePlus\\\\] status: Valid, expires in (4w 2d|4w 1d 23h 59m \\\\d+s), instances total: 100 used: 4 \\\\(4.00%\\\\) free: 96 \\\\(96.00%\\\\) \\\\| 'license.expires.days'=(29|30)d;;;0; 'license.instances.usage.count'=4;;;0;100 'license.instances.free.count'=96;;;0;100 'license.instances.usage.percentage'=4.00%;;;0;100$
    ...    2
    ...    --warning-expires=31:
    ...    ^WARNING: License 'Example Company' \\\\[type: Subscription\\\\] \\\\[edition: EnterprisePlus\\\\] expires in (4w 2d|4w 1d 23h 59m \\\\d+s) \\\\| 'license.expires.days'=(29|30)d;31:;;0; 'license.instances.usage.count'=4;;;0;100 'license.instances.free.count'=96;;;0;100 'license.instances.usage.percentage'=4.00%;;;0;100$
