*** Settings ***
Documentation       Prometheus cAdvisor exporter - memory mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}metrics.mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::exporters::cadvisor::plugin
...                 --mode=memory
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --url-path=/api/v1


*** Test Cases ***
Memory ${tc}
    [Tags]    cloud    prometheus    cadvisor

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
    ...    --verbose
    ...    OK: All containers memory usage are ok | 'web-1~nginx#memory.used.bytes'=52428800B;;;0;104857600 'web-1~nginx#memory.working.bytes'=41943040B;;;0;104857600 'web-1~nginx#cache.usage.bytes'=10485760B;;;0; 'web-1~nginx#rss.usage.bytes'=39845888B;;;0; 'web-1~nginx#swap.usage.bytes'=0B;;;0; 'multi~app#memory.used.bytes'=31457280B;;;0;0 'multi~app#memory.working.bytes'=26214400B;;;0;0 'multi~app#cache.usage.bytes'=5242880B;;;0; 'multi~app#rss.usage.bytes'=23068672B;;;0; 'multi~app#swap.usage.bytes'=0B;;;0; 'multi~sidecar#memory.used.bytes'=8388608B;;;0;0 'multi~sidecar#memory.working.bytes'=6291456B;;;0;0 'multi~sidecar#cache.usage.bytes'=2097152B;;;0; 'multi~sidecar#rss.usage.bytes'=5242880B;;;0; 'multi~sidecar#swap.usage.bytes'=0B;;;0;\nContainer 'nginx' [pod: web-1] Memory Usage: 50.00 MB (50.00% of 100.00 MB), Working: 40.00 MB (40.00% of 100.00 MB), Cache: 10.00 MB, Rss: 38.00 MB, Swap: 0.00 B\nContainer 'app' [pod: multi] Memory Usage: 30.00 MB (unlimited), Working: 25.00 MB (unlimited), Cache: 5.00 MB, Rss: 22.00 MB, Swap: 0.00 B\nContainer 'sidecar' [pod: multi] Memory Usage: 8.00 MB (unlimited), Working: 6.00 MB (unlimited), Cache: 2.00 MB, Rss: 5.00 MB, Swap: 0.00 B
    ...    2
    ...    --container='container=""'
    ...    OK: All containers memory usage are ok | 'web-1#memory.used.bytes'=62914560B;;;0;0 'web-1#memory.working.bytes'=52428800B;;;0;0 'web-1#cache.usage.bytes'=10485760B;;;0; 'web-1#rss.usage.bytes'=47185920B;;;0; 'web-1#swap.usage.bytes'=0B;;;0; 'multi#memory.used.bytes'=41943040B;;;0;0 'multi#memory.working.bytes'=36700160B;;;0;0 'multi#cache.usage.bytes'=5242880B;;;0; 'multi#rss.usage.bytes'=31457280B;;;0; 'multi#swap.usage.bytes'=0B;;;0;
    ...    3
    ...    --container='name="haproxy"'
    ...    OK: Container 'haproxy' Memory Usage: 20.00 MB (unlimited), Working: 15.00 MB (unlimited), Cache: 5.00 MB, Rss: 12.00 MB, Swap: 1.00 MB | 'haproxy#memory.used.bytes'=20971520B;;;0;0 'haproxy#memory.working.bytes'=15728640B;;;0;0 'haproxy#cache.usage.bytes'=5242880B;;;0; 'haproxy#rss.usage.bytes'=12582912B;;;0; 'haproxy#swap.usage.bytes'=1048576B;;;0;
    ...    4
    ...    --pod='pod="web-1"' --verbose
    ...    OK: All containers memory usage are ok | 'web-1~nginx#memory.used.bytes'=52428800B;;;0;104857600 'web-1~nginx#memory.working.bytes'=41943040B;;;0;104857600 'web-1~nginx#cache.usage.bytes'=10485760B;;;0; 'web-1~nginx#rss.usage.bytes'=39845888B;;;0; 'web-1~nginx#swap.usage.bytes'=0B;;;0; 'web-1~nginx#memory.used.bytes'=73400320B;;;0;104857600 'web-1~nginx#memory.working.bytes'=68157440B;;;0;104857600 'web-1~nginx#cache.usage.bytes'=5242880B;;;0; 'web-1~nginx#rss.usage.bytes'=62914560B;;;0; 'web-1~nginx#swap.usage.bytes'=0B;;;0;\nContainer 'nginx' [pod: web-1] Memory Usage: 50.00 MB (50.00% of 100.00 MB), Working: 40.00 MB (40.00% of 100.00 MB), Cache: 10.00 MB, Rss: 38.00 MB, Swap: 0.00 B\nContainer 'nginx' [pod: web-1] Memory Usage: 70.00 MB (70.00% of 100.00 MB), Working: 65.00 MB (65.00% of 100.00 MB), Cache: 5.00 MB, Rss: 60.00 MB, Swap: 0.00 B
    ...    5
    ...    --warning-usage=40
    ...    WARNING: Container 'nginx' [pod: web-1] Memory Usage: 50.00 MB (50.00% of 100.00 MB) | 'web-1~nginx#memory.used.bytes'=52428800B;0:41943040;;0;104857600 'web-1~nginx#memory.working.bytes'=41943040B;;;0;104857600 'web-1~nginx#cache.usage.bytes'=10485760B;;;0; 'web-1~nginx#rss.usage.bytes'=39845888B;;;0; 'web-1~nginx#swap.usage.bytes'=0B;;;0; 'multi~app#memory.used.bytes'=31457280B;0:40;;0;0 'multi~app#memory.working.bytes'=26214400B;;;0;0 'multi~app#cache.usage.bytes'=5242880B;;;0; 'multi~app#rss.usage.bytes'=23068672B;;;0; 'multi~app#swap.usage.bytes'=0B;;;0; 'multi~sidecar#memory.used.bytes'=8388608B;0:40;;0;0 'multi~sidecar#memory.working.bytes'=6291456B;;;0;0 'multi~sidecar#cache.usage.bytes'=2097152B;;;0; 'multi~sidecar#rss.usage.bytes'=5242880B;;;0; 'multi~sidecar#swap.usage.bytes'=0B;;;0;
    ...    6
    ...    --units=B --critical-rss=30000000
    ...    CRITICAL: Container 'nginx' [pod: web-1] Memory Rss: 38.00 MB | 'web-1~nginx#memory.used.bytes'=52428800B;;;0;104857600 'web-1~nginx#memory.working.bytes'=41943040B;;;0;104857600 'web-1~nginx#cache.usage.bytes'=10485760B;;;0; 'web-1~nginx#rss.usage.bytes'=39845888B;;0:30000000;0; 'web-1~nginx#swap.usage.bytes'=0B;;;0; 'multi~app#memory.used.bytes'=31457280B;;;0;0 'multi~app#memory.working.bytes'=26214400B;;;0;0 'multi~app#cache.usage.bytes'=5242880B;;;0; 'multi~app#rss.usage.bytes'=23068672B;;0:30000000;0; 'multi~app#swap.usage.bytes'=0B;;;0; 'multi~sidecar#memory.used.bytes'=8388608B;;;0;0 'multi~sidecar#memory.working.bytes'=6291456B;;;0;0 'multi~sidecar#cache.usage.bytes'=2097152B;;;0; 'multi~sidecar#rss.usage.bytes'=5242880B;;0:30000000;0; 'multi~sidecar#swap.usage.bytes'=0B;;;0;
    ...    7
    ...    --container='container="absent"'
    ...    UNKNOWN: No containers found.
    ...    8
    ...    --pod='not a filter'
    ...    UNKNOWN: Need to specify --pod option as a PromQL filter.
