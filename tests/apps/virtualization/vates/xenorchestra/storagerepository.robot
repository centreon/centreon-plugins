*** Settings ***
Documentation       apps::virtualization::vates::xenorchestra::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}..${/}mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::virtualization::vates::xenorchestra::plugin
...                 --mode=storage-repository
...                 --password=C3POR2P2
...                 --username=obi-wan
...                 --hostname=127.0.0.1
...                 --proto=http
...                 --port=3000


*** Test Cases ***
Storage Repository ${tc}
    [Tags]    apps    virtualization    xenorchestra
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
    ...    OK: All storage repositories are ok | 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'Local storage#storage.space.total.bytes'=61488377856B;;;0; 'Local storage#storage.space.usage.percentage'=12.22%;;;0;100 'ISO#storage.space.total.bytes'=18843783168B;;;0; 'ISO#storage.space.usage.percentage'=17.73%;;;0;100 'nfs-HA-storage#storage.space.total.bytes'=400732192768B;;;0; 'nfs-HA-storage#storage.space.usage.percentage'=33.12%;;;0;100 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'HA#storage.space.total.bytes'=32143048704B;;;0; 'HA#storage.space.usage.percentage'=7.08%;;;0;100
    ...    2
    ...    --include-name="Local storage"
    ...    OK: storage repository 'Local storage' total size: 57.27GB, used: 12.22 % | 'Local storage#storage.space.total.bytes'=61488377856B;;;0; 'Local storage#storage.space.usage.percentage'=12.22%;;;0;100
    ...    3
    ...    --exclude-name="Local storage"
    ...    OK: All storage repositories are ok | 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'ISO#storage.space.total.bytes'=18843783168B;;;0; 'ISO#storage.space.usage.percentage'=17.73%;;;0;100 'nfs-HA-storage#storage.space.total.bytes'=400732192768B;;;0; 'nfs-HA-storage#storage.space.usage.percentage'=33.12%;;;0;100 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'HA#storage.space.total.bytes'=32143048704B;;;0; 'HA#storage.space.usage.percentage'=7.08%;;;0;100
    ...    4
    ...    --include-uuid=6c9bb023-f6da-0fe5-647c-23aae1dca3c7
    ...    OK: storage repository 'Local storage' total size: 57.27GB, used: 12.22 % | 'Local storage#storage.space.total.bytes'=61488377856B;;;0; 'Local storage#storage.space.usage.percentage'=12.22%;;;0;100
    ...    5
    ...    --exclude-uuid=6c9bb023-f6da-0fe5-647c-23aae1dca3c7
    ...    OK: All storage repositories are ok | 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'ISO#storage.space.total.bytes'=18843783168B;;;0; 'ISO#storage.space.usage.percentage'=17.73%;;;0;100 'nfs-HA-storage#storage.space.total.bytes'=400732192768B;;;0; 'nfs-HA-storage#storage.space.usage.percentage'=33.12%;;;0;100 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'HA#storage.space.total.bytes'=32143048704B;;;0; 'HA#storage.space.usage.percentage'=7.08%;;;0;100
    ...    6
    ...    --include-sr-type=nfs
    ...    OK: storage repository 'nfs-HA-storage' total size: 373.21GB, used: 33.12 % | 'nfs-HA-storage#storage.space.total.bytes'=400732192768B;;;0; 'nfs-HA-storage#storage.space.usage.percentage'=33.12%;;;0;100
    ...    7
    ...    --exclude-sr-type=udev
    ...    OK: All storage repositories are ok | 'Local storage#storage.space.total.bytes'=61488377856B;;;0; 'Local storage#storage.space.usage.percentage'=12.22%;;;0;100 'ISO#storage.space.total.bytes'=18843783168B;;;0; 'ISO#storage.space.usage.percentage'=17.73%;;;0;100 'nfs-HA-storage#storage.space.total.bytes'=400732192768B;;;0; 'nfs-HA-storage#storage.space.usage.percentage'=33.12%;;;0;100 'HA#storage.space.total.bytes'=32143048704B;;;0; 'HA#storage.space.usage.percentage'=7.08%;;;0;100
    ...    8
    ...    --include-pool=does-not-exist
    ...    UNKNOWN: No storage repository found, check filters
    ...    9
    ...    --exclude-pool=00969214-df4d-83cb-78d5-bec9181903d4
    ...    UNKNOWN: No storage repository found, check filters
    ...    10
    ...    --warning-usage=10 --critical-usage=20 --exclude-sr-type=udev
    ...    CRITICAL: storage repository 'nfs-HA-storage' used: 33.12 % WARNING: storage repository 'Local storage' used: 12.22 % - storage repository 'ISO' used: 17.73 % | 'Local storage#storage.space.total.bytes'=61488377856B;;;0; 'Local storage#storage.space.usage.percentage'=12.22%;0:10;0:20;0;100 'ISO#storage.space.total.bytes'=18843783168B;;;0; 'ISO#storage.space.usage.percentage'=17.73%;0:10;0:20;0;100 'nfs-HA-storage#storage.space.total.bytes'=400732192768B;;;0; 'nfs-HA-storage#storage.space.usage.percentage'=33.12%;0:10;0:20;0;100 'HA#storage.space.total.bytes'=32143048704B;;;0; 'HA#storage.space.usage.percentage'=7.08%;0:10;0:20;0;100
    ...    11
    ...    --include-name="Local storage" --warning-total-size=50GB
    ...    WARNING: storage repository 'Local storage' total size: 57.27GB | 'Local storage#storage.space.total.bytes'=61488377856B;0:53687091200;;0; 'Local storage#storage.space.usage.percentage'=12.22%;;;0;100
    ...    12
    ...    --include-name="Local storage" --critical-total-size=50GB
    ...    CRITICAL: storage repository 'Local storage' total size: 57.27GB | 'Local storage#storage.space.total.bytes'=61488377856B;;0:53687091200;0; 'Local storage#storage.space.usage.percentage'=12.22%;;;0;100
    ...    13
    ...    --include-pool=00969214-df4d-83cb-78d5-bec9181903d4
    ...    OK: All storage repositories are ok | 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'Local storage#storage.space.total.bytes'=61488377856B;;;0; 'Local storage#storage.space.usage.percentage'=12.22%;;;0;100 'ISO#storage.space.total.bytes'=18843783168B;;;0; 'ISO#storage.space.usage.percentage'=17.73%;;;0;100 'nfs-HA-storage#storage.space.total.bytes'=400732192768B;;;0; 'nfs-HA-storage#storage.space.usage.percentage'=33.12%;;;0;100 'DVD drives#storage.space.total.bytes'=1073741312B;;;0; 'DVD drives#storage.space.usage.percentage'=100.00%;;;0;100 'HA#storage.space.total.bytes'=32143048704B;;;0; 'HA#storage.space.usage.percentage'=7.08%;;;0;100
