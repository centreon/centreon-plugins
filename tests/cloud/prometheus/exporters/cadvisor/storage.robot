*** Settings ***
Documentation       Prometheus cAdvisor exporter - storage mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}metrics.mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::prometheus::exporters::cadvisor::plugin
...                 --mode=storage
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --url-path=/api/v1


*** Test Cases ***
Storage ${tc}
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
    ...    OK: All containers storages usage are ok | 'used_multi_app_/dev/vda1'=104857600B;;;0;1048576000 'used_web-1_nginx_/dev/vda1'=209715200B;;;0;1048576000\nChecking container 'app' [pod: multi]\n${SPACE}${SPACE}${SPACE}${SPACE}Storage '/dev/vda1' Usage Limit: 1000.00 MB Used: 100.00 MB (10.00%) Free: 900.00 MB (90.00%)\nChecking container 'nginx' [pod: web-1]\n${SPACE}${SPACE}${SPACE}${SPACE}Storage '/dev/vda1' Usage Limit: 1000.00 MB Used: 200.00 MB (20.00%) Free: 800.00 MB (80.00%)
    ...    2
    ...    --container='container=""'
    ...    OK: Pod 'web-1' Storage '/dev/vda1' Usage Limit: 1000.00 MB Used: 300.00 MB (30.00%) Free: 700.00 MB (70.00%) | 'used'=314572800B;;;0;1048576000
    ...    3
    ...    --container='name="haproxy"'
    ...    OK: Container 'haproxy' Storage '/dev/vda1' Usage Limit: 1000.00 MB Used: 900.00 MB (90.00%) Free: 100.00 MB (10.00%) | 'used'=943718400B;;;0;1048576000
    ...    4
    ...    --warning-usage=15 --critical-usage=80
    ...    WARNING: Container 'nginx' [pod: web-1] Storage '/dev/vda1' Usage Limit: 1000.00 MB Used: 200.00 MB (20.00%) Free: 800.00 MB (80.00%) | 'used_multi_app_/dev/vda1'=104857600B;0:157286400;0:838860800;0;1048576000 'used_web-1_nginx_/dev/vda1'=209715200B;0:157286400;0:838860800;0;1048576000
    ...    5
    ...    --container='name="haproxy"' --units=B --free --critical-usage=200000000:
    ...    CRITICAL: Container 'haproxy' Storage '/dev/vda1' Usage Limit: 1000.00 MB Used: 900.00 MB (90.00%) Free: 100.00 MB (10.00%) | 'free'=104857600B;;200000000:;0;1048576000
    ...    6
    ...    --container='container="absent"'
    ...    UNKNOWN: No containers found.
    ...    7
    ...    --pod='not a filter'
    ...    UNKNOWN: Need to specify --pod option as a PromQL filter.
