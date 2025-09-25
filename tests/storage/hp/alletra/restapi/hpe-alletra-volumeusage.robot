*** Settings ***
Documentation       HPE Alletra Storage REST API Mode Volume Usage 

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
...                 --mode volume-usage
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}

*** Test Cases ***
VolumeUsage ${tc}
    [Tags]    storage     api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings   ${command}    ${expected_string}


    Examples:        tc       extraoptions                                                                  expected_string    --
            ...      1        ${EMPTY}                                                                      OK: All volumes are ok | 'mtest#volume.space.usage.bytes'=549755813888B;;;0;549755813888 'mtest#volume.space.free.bytes'=0B;;;0;549755813888 'mtest#volume.space.usage.percentage'=100.00%;;;0;100 'stest#volume.space.usage.bytes'=23991418880B;;;0;128849018880 'stest#volume.space.free.bytes'=104857600000B;;;0;128849018880 'stest#volume.space.usage.percentage'=18.62%;;;0;100 'test#volume.space.usage.bytes'=10737418240B;;;0;10737418240 'test#volume.space.free.bytes'=0B;;;0;10737418240 'test#volume.space.usage.percentage'=100.00%;;;0;100
            ...      2        --filter-id=1                                                                 OK: Volume 'stest' (#1) Total: 120.00 GB Reserved: 120.00 GB Used: 22.34 GB (18.62%) Free: 97.66 GB (81.38%) | 'stest#volume.space.usage.bytes'=23991418880B;;;0;128849018880 'stest#volume.space.free.bytes'=104857600000B;;;0;128849018880 'stest#volume.space.usage.percentage'=18.62%;;;0;100
            ...      3        --filter-name=mtest                                                           OK: Volume 'mtest' (#2) Total: 512.00 GB Reserved: 512.00 GB Used: 512.00 GB (100.00%) Free: 0.00 B (0.00%) | 'mtest#volume.space.usage.bytes'=549755813888B;;;0;549755813888 'mtest#volume.space.free.bytes'=0B;;;0;549755813888 'mtest#volume.space.usage.percentage'=100.00%;;;0;100
            ...      4        --filter-counters=usage-prct --critical-usage-prct=90                         CRITICAL: Volume 'mtest' (#2) Used : 100.00 % - Volume 'test' (#0) Used : 100.00 % | 'mtest#volume.space.usage.percentage'=100.00%;;0:90;0;100 'stest#volume.space.usage.percentage'=18.62%;;0:90;0;100 'test#volume.space.usage.percentage'=100.00%;;0:90;0;100
            ...      5        --filter-counters=usage-free --critical-usage-free=:10                        CRITICAL: Volume 'stest' (#1) Total: 120.00 GB Reserved: 120.00 GB Used: 22.34 GB (18.62%) Free: 97.66 GB (81.38%) | 'mtest#volume.space.free.bytes'=0B;;0:10;0;549755813888 'stest#volume.space.free.bytes'=104857600000B;;0:10;0;128849018880 'test#volume.space.free.bytes'=0B;;0:10;0;10737418240
            ...      6        --filter-counters='^usage$' --warning-usage=:10                               WARNING: Volume 'mtest' (#2) Total: 512.00 GB Reserved: 512.00 GB Used: 512.00 GB (100.00%) Free: 0.00 B (0.00%) - Volume 'stest' (#1) Total: 120.00 GB Reserved: 120.00 GB Used: 22.34 GB (18.62%) Free: 97.66 GB (81.38%) - Volume 'test' (#0) Total: 10.00 GB Reserved: 10.00 GB Used: 10.00 GB (100.00%) Free: 0.00 B (0.00%) | 'mtest#volume.space.usage.bytes'=549755813888B;0:10;;0;549755813888 'stest#volume.space.usage.bytes'=23991418880B;0:10;;0;128849018880 'test#volume.space.usage.bytes'=10737418240B;0:10;;0;10737418240
