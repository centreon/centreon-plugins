*** Settings ***
Documentation       apps::voip::3cx::restapi::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}voip.mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::voip::3cx::restapi::plugin
...                 --mode=system
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=api-username
...                 --api-password=api-password
...                 --auth-mode=oauth2
...                 --timeout=10


*** Test Cases ***
System ${tc}
    [Tags]    apps    voip    restapi
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
    ...    OK: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%), extensions registered: 49, extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) - All services are ok | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    2
    ...    --include-category=NONE
    ...    OK: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%), extensions registered: 49, extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) - All services are ok | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    3
    ...    --exclude-category=.
    ...    OK: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%), extensions registered: 49, extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) - All services are ok | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    4
    ...    --include-service=HasUnregisteredTrunks --filter-counters=status
    ...    OK: 3CX 'HasUnregisteredTrunks' status : false
    ...    5
    ...    --exclude-service=HasUnregisteredSystemExtensions --critical-status='\\\%{error} !~ /true/' --filter-counters=status
    ...    CRITICAL: 3CX 'HasNotRunningServices' status : false - 3CX 'HasUnregisteredTrunks' status : false - 3CX 'HasUpdatesAvailable' status : false
    ...    6
    ...    --unknown-status=1
    ...    UNKNOWN: 3CX 'HasNotRunningServices' status : false - 3CX 'HasUnregisteredSystemExtensions' status : false - 3CX 'HasUnregisteredTrunks' status : false - 3CX 'HasUpdatesAvailable' status : false | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    7
    ...    --warning-status=1
    ...    WARNING: 3CX 'HasNotRunningServices' status : false - 3CX 'HasUnregisteredSystemExtensions' status : false - 3CX 'HasUnregisteredTrunks' status : false - 3CX 'HasUpdatesAvailable' status : false | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    8
    ...    --critical-status=1
    ...    CRITICAL: 3CX 'HasNotRunningServices' status : false - 3CX 'HasUnregisteredSystemExtensions' status : false - 3CX 'HasUnregisteredTrunks' status : false - 3CX 'HasUpdatesAvailable' status : false | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    9
    ...    --warning-calls-active-usage=2:
    ...    WARNING: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%) | 'system.calls.active.usage.count'=1;2:;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    10
    ...    --critical-calls-active-usage=2:
    ...    CRITICAL: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%) | 'system.calls.active.usage.count'=1;;2:;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    11
    ...    --warning-calls-active-free=1
    ...    WARNING: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;0:1;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    12
    ...    --critical-calls-active-free=1
    ...    CRITICAL: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;0:1;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    13
    ...    --warning-calls-active-usage-prct=1
    ...    WARNING: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;0:1;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    14
    ...    --critical-calls-active-usage-prct=1
    ...    CRITICAL: active calls usage total: 24 used: 1 (4.17%) free: 23 (4.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;0:1;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    15
    ...    --warning-extensions-usage=1
    ...    WARNING: extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;0:1;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    16
    ...    --critical-extensions-usage=1
    ...    CRITICAL: extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;0:1;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    17
    ...    --warning-extensions-free=1
    ...    WARNING: extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;0:1;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    18
    ...    --critical-extensions-free=1
    ...    CRITICAL: extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;0:1;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    19
    ...    --warning-extensions-registered=1
    ...    WARNING: extensions registered: 49 | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;0:1;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    20
    ...    --critical-extensions-registered=1
    ...    CRITICAL: extensions registered: 49 | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;0:1;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;;0;100
    ...    21
    ...    --warning-extensions-usage-prct=1
    ...    WARNING: extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;0:1;;0;100
    ...    22
    ...    --critical-extensions-usage-prct=1
    ...    CRITICAL: extensions usage total: 120 used: 53 (44.17%) free: 67 (44.17%) | 'system.calls.active.usage.count'=1;;;0;24 'system.calls.active.free.count'=23;;;0;24 'system.calls.active.usage.percentage'=4.17;;;0;24 'system.extensions.registered.count'=49;;;0;53 'system.extensions.usage.count'=53;;;0;120 'system.extensions.free.count'=67;;;0;120 'system.extensions.usage.percentage'=44.17%;;0:1;0;100
