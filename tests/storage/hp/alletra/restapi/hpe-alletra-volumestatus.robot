*** Settings ***
Documentation       HPE Alletra Storage REST API Mode Volume Status

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
...                 --mode volume-status
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
VolumeStatus ${tc}
    [Tags]    storage     api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings   ${command}    ${expected_string}


    Examples:        tc       extraoptions                                                                                                                   expected_string    --
            ...      1        ${EMPTY}                                                                                                                       CRITICAL: Volume #2 (mtest) uuid: AEZDSSFDDSD (readonly: 0, compression: NA, provisioning: FULL) WARNING: Volume #1 (stest) uuid: SFFDSDDSDSD (readonly: 0, compression: NA, provisioning: FULL) | 'volumes.total.count'=3;;;0; 'volumes.normal.count'=1;;;0;3 'volumes.degraded.count'=1;;;0;3 'volumes.failed.count'=1;;;0;3 'volumes.unknown.count'=0;;;0;3
            ...      2        --critical-status='' --warning-status='' --warning-volumes-total=4: --filter-counters=volumes-total                            WARNING: Volumes total: 3 | 'volumes.total.count'=3;4:;;0;
            ...      3        --mode=volume-status --critical-status='' --warning-status='' --warning-volumes-normal=:0 --filter-counters=volumes-normal     WARNING: Volumes normal: 1 | 'volumes.normal.count'=1;0:0;;0;3
            ...      4        --critical-status='' --warning-status='' --warning-volumes-degraded=:0 --filter-counters=volumes-degraded                      WARNING: Volumes degraded: 1 | 'volumes.degraded.count'=1;0:0;;0;3
            ...      5        --critical-status='' --warning-status='' --warning-volumes-failed=:0 --filter-counters=volumes-failed                          WARNING: Volumes failed: 1 | 'volumes.failed.count'=1;0:0;;0;3
            ...      6        --critical-status='' --warning-status='' --critical-volumes-unknown=@0:0 --filter-counters=volumes-unknown                     CRITICAL: Volumes unknown: 0 | 'volumes.unknown.count'=0;;@0:0;0;3
            ...      7        --filter-name=mtest                                                                                                            CRITICAL: Volume #2 (mtest) uuid: AEZDSSFDDSD (readonly: 0, compression: NA, provisioning: FULL) | 'volumes.total.count'=1;;;0; 'volumes.normal.count'=0;;;0;1 'volumes.degraded.count'=0;;;0;1 'volumes.failed.count'=1;;;0;1 'volumes.unknown.count'=0;;;0;1
            ...      8        --filter-id=0                                                                                                                  OK: Volumes total: 1, normal: 1, degraded: 0, failed: 0, unknown: 0 - Volume #0 (test) uuid: ZAZZAZZA (readonly: 0, compression: NA, provisioning: FULL) | 'volumes.total.count'=1;;;0; 'volumes.normal.count'=1;;;0;1 'volumes.degraded.count'=0;;;0;1 'volumes.failed.count'=0;;;0;1 'volumes.unknown.count'=0;;;0;1
