*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vcenter::plugin
...                 --mode=datastore-usage
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Datastore-Usage ${tc}
    [Tags]    apps    api    vmware    vsphere8    vcenter
    ${command_curl}    Catenate    ${CMD} --http-backend=curl ${extraoptions}
    ${command_lwp}    Catenate    ${CMD} --http-backend=lwp ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command_curl}    ${expected_result}
    Ctn Run Command And Check Result As Strings    ${command_lwp}    ${expected_result}

    Examples:    tc     extraoptions                                                        expected_result   --
        ...      1      --include-name=Prod                                                 OK: 'Datastore - Production' accessible, Used: 637.46 GB (52.66%) - Free: 573.04 GB (47.34%) - Total: 1.18 TB | 'Datastore - Production#datastore.space.usage.bytes'=684471615488B;;;0;1299764477952 'Datastore - Production#datastore.space.free.bytes'=615292862464B;;;0;1299764477952 'Datastore - Production#datastore.space.usage.percentage'=52.66%;;;0;100
        ...      2      --include-name=Prod --warning-usage=5                               WARNING: Used: 637.46 GB (52.66%) - Free: 573.04 GB (47.34%) - Total: 1.18 TB | 'Datastore - Production#datastore.space.usage.bytes'=684471615488B;0:5;;0;1299764477952 'Datastore - Production#datastore.space.free.bytes'=615292862464B;;;0;1299764477952 'Datastore - Production#datastore.space.usage.percentage'=52.66%;;;0;100
        ...      3      --include-name=Prod --critical-usage=5                              CRITICAL: Used: 637.46 GB (52.66%) - Free: 573.04 GB (47.34%) - Total: 1.18 TB | 'Datastore - Production#datastore.space.usage.bytes'=684471615488B;;0:5;0;1299764477952 'Datastore - Production#datastore.space.free.bytes'=615292862464B;;;0;1299764477952 'Datastore - Production#datastore.space.usage.percentage'=52.66%;;;0;100
        ...      4      --include-name=Prod --warning-usage-free=1000000000000:             WARNING: Used: 637.46 GB (52.66%) - Free: 573.04 GB (47.34%) - Total: 1.18 TB | 'Datastore - Production#datastore.space.usage.bytes'=684471615488B;;;0;1299764477952 'Datastore - Production#datastore.space.free.bytes'=615292862464B;1000000000000:;;0;1299764477952 'Datastore - Production#datastore.space.usage.percentage'=52.66%;;;0;100
        ...      5      --include-name=Prod --critical-usage-free=1000000000000:            CRITICAL: Used: 637.46 GB (52.66%) - Free: 573.04 GB (47.34%) - Total: 1.18 TB | 'Datastore - Production#datastore.space.usage.bytes'=684471615488B;;;0;1299764477952 'Datastore - Production#datastore.space.free.bytes'=615292862464B;;1000000000000:;0;1299764477952 'Datastore - Production#datastore.space.usage.percentage'=52.66%;;;0;100
        ...      6      --filter-counters=status                                            CRITICAL: 'Datastore - Developpement 7200' NOT accessible
        ...      7      --filter-counters=status --critical-status=0                        OK: All datastores are ok
        ...      8      --filter-counters=status --critical-status=0 --warning-status=1     WARNING: 'Datastore - Systeme' accessible - 'Datastore - ESX02' accessible - 'Datastore - ESX03' accessible - 'Datastore - Developpement 15000' accessible - 'Datastore - Developpement 7200' NOT accessible - 'Datastore - ESX01' accessible - 'Datastore - Developpement' accessible - 'Datastore - Production' accessible
        ...      9      --include-name=Prod --warning-usage-prct=5                          WARNING: Used: 637.46 GB (52.66%) - Free: 573.04 GB (47.34%) - Total: 1.18 TB | 'Datastore - Production#datastore.space.usage.bytes'=684471615488B;;;0;1299764477952 'Datastore - Production#datastore.space.free.bytes'=615292862464B;;;0;1299764477952 'Datastore - Production#datastore.space.usage.percentage'=52.66%;0:5;;0;100
        ...     10      --include-name=Prod --critical-usage-prct=5                         CRITICAL: Used: 637.46 GB (52.66%) - Free: 573.04 GB (47.34%) - Total: 1.18 TB | 'Datastore - Production#datastore.space.usage.bytes'=684471615488B;;;0;1299764477952 'Datastore - Production#datastore.space.free.bytes'=615292862464B;;;0;1299764477952 'Datastore - Production#datastore.space.usage.percentage'=52.66%;;0:5;0;100
