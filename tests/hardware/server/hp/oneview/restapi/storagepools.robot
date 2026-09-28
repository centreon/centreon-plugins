*** Settings ***
Documentation       HP OneView Restapi Storage Pools plugin

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
...                 --mode=storage-pools


*** Test Cases ***
Storage Pools ${tc}
    [Tags]    hardware    server    hp    oneview    api    storage-pools    mockoon
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
    ...    WARNING: Storage pool 'CENTREON3' status : Warning | 'CENTREON1#pool.space.usage.bytes'=13194139533312B;;;0;21990232555520 'CENTREON1#pool.space.free.bytes'=8796093022208B;;;0;21990232555520 'CENTREON1#pool.space.usage.percentage'=60.00%;;;0;100 'CENTREON2#pool.space.usage.bytes'=8796093022208B;;;0;10995116277760 'CENTREON2#pool.space.free.bytes'=2199023255552B;;;0;10995116277760 'CENTREON2#pool.space.usage.percentage'=80.00%;;;0;100 'CENTREON3#pool.space.usage.bytes'=4947802324992B;;;0;5497558138880 'CENTREON3#pool.space.free.bytes'=549755813888B;;;0;5497558138880 'CENTREON3#pool.space.usage.percentage'=90.00%;;;0;100
    ...    2
    ...    --filter-name='CENTREON1'
    ...    OK: Storage pool 'CENTREON1' status : OK, space usage total: 20.00 TB used: 12.00 TB (60.00%) free: 8.00 TB (40.00%) | 'CENTREON1#pool.space.usage.bytes'=13194139533312B;;;0;21990232555520 'CENTREON1#pool.space.free.bytes'=8796093022208B;;;0;21990232555520 'CENTREON1#pool.space.usage.percentage'=60.00%;;;0;100
    ...    3
    ...    --filter-name='CENTREON1' --warning-status='\\\%{status} =~ /OK/i'
    ...    WARNING: Storage pool 'CENTREON1' status : OK | 'CENTREON1#pool.space.usage.bytes'=13194139533312B;;;0;21990232555520 'CENTREON1#pool.space.free.bytes'=8796093022208B;;;0;21990232555520 'CENTREON1#pool.space.usage.percentage'=60.00%;;;0;100
    ...    4
    ...    --filter-name='CENTREON1' --critical-usage-prct=50
    ...    CRITICAL: Storage pool 'CENTREON1' used : 60.00 % | 'CENTREON1#pool.space.usage.bytes'=13194139533312B;;;0;21990232555520 'CENTREON1#pool.space.free.bytes'=8796093022208B;;;0;21990232555520 'CENTREON1#pool.space.usage.percentage'=60.00%;;0:50;0;100
    ...    5
    ...    --filter-name='DOES_NOT_EXIST'
    ...    UNKNOWN: No storage pool found
