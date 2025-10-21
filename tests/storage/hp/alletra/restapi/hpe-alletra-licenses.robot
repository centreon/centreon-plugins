*** Settings ***
Documentation       HPE Alletra Storage REST API Mode Licenses

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-alletra.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS} 
...                 --plugin=storage::hp::alletra::restapi::plugin
...                 --mode licenses
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
Licenses ${tc}
    [Tags]    storage     api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}


    Examples:        tc       extraoptions                                                expected_regexp    --
            ...      1        ${EMPTY}                                                    CRITICAL: Number of expired licenses: 1 | 'licenses.total.count'=9;;0:;0; 'licenses.expired.count'=1;;0:0;0;1 'LICENSE 2#license.expiration.seconds'=0s;;;0; 'LICENSE 3#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 5#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 6#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 8#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 9#license.expiration.seconds'=(\\\\d+)s;;;0;
            ...      2        --filter-counters=license-expiration                        OK: All licenses are ok | 'LICENSE 2#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 3#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 5#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 6#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 8#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 9#license.expiration.seconds'=(\\\\d+)s;;;0;
            ...      3        --warning-total=10: --critical-expired=''                   WARNING: Number of licenses: 9 | 'licenses.total.count'=9;10:;;0; 'licenses.expired.count'=0;;;0;9 'LICENSE 2#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 3#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 5#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 6#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 8#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 9#license.expiration.seconds'=(\\\\d+)s;;;0;
            ...      4        --critical-expired='' --warning-expired=':0'                WARNING: Number of expired licenses: 1 | 'licenses.total.count'=9;;0:;0; 'licenses.expired.count'=1;0:0;;0;1 'LICENSE 2#license.expiration.seconds'=0s;;;0; 'LICENSE 3#license.expiration.seconds'(\\\\d+)s;;;0; 'LICENSE 5#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 6#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 8#license.expiration.seconds'=(\\\\d+)s;;;0; 'LICENSE 9#license.expiration.seconds'=(\\\\d+)s;;;0;
            ...      5        --critical-expired='' --warning-license-expiration='1:'     WARNING: License 'LICENSE 1' expires: never. LICENSE 1 has permanent license. - License 'LICENSE 2' expires: 2020-04-20T02:00:00+02:00. LICENSE 2 license has expired. - License 'LICENSE 4' expires: never. LICENSE 4 has permanent license. - License 'LICENSE 7' expires: never. LICENSE 7 has permanent license. | 'licenses.total.count'=9;;1:;0; 'licenses.expired.count'=1;;;0;9 'LICENSE 2#license.expiration.seconds'=0s;1:;;0; 'LICENSE 3#license.expiration.seconds'=(\\\\d+)s;1:;;0; 'LICENSE 5#license.expiration.seconds'=(\\\\d+)s;1:;;0; 'LICENSE 6#license.expiration.seconds'=(\\\\d+)s;1:;;0; 'LICENSE 8#license.expiration.seconds'=(\\\\d+)s;1:;;0; 'LICENSE 9#license.expiration.seconds'=(\\\\d+)s;1:;;0;
