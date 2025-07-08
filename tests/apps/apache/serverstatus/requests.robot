# Note: With these tests a counter is incremented in the Mockoon mock data.
# To reset it, make sure to restart the Mockoon server before each robot execution.

*** Settings ***
Documentation       Check Apache WebServer Requests statistics

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}serverstatus.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::apache::serverstatus::plugin
...                 --mode=requests
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}

*** Test Cases ***
Requests ${tc}
    [Tags]    apps    apache    serverstatus

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                       expected_result    --
        ...      1     ${EMPTY}                                            OK: bytesPerSec : Buffer creation, accessPerSec : Buffer creation, RequestPerSec: 300.00, BytesPerRequest: 2.11 MB | 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      2     --urlpath=/server-status-2                          OK: BytesPerSec: 607.00 KB, AccessPerSec: 484.00, RequestPerSec: 300.00, BytesPerRequest: 1.25 KB | 'apache.bytes.persecond'=621568.00B;;;0; 'apache.access.persecond'=484.00;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      3     --warning-apache.bytes.persecond=:400               WARNING: BytesPerSec: 57.61 MB | 'apache.bytes.persecond'=60408832.00B;0:400;;0; 'apache.access.persecond'=474516.00;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      4     --critical-apache-access-persecond=:10 --urlpath=/server-status-2    CRITICAL: AccessPerSec: 484.00 | 'apache.bytes.persecond'=621568.00B;;;0; 'apache.access.persecond'=484.00;;0:10;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      5     --critical-apache-request-average-persecond=400:    CRITICAL: RequestPerSec: 300.00 | 'apache.bytes.persecond'=60408832.00B;;;0; 'apache.access.persecond'=474516.00;;;0; 'apache.request.average.persecond'=300.00;;400:;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      6     --warning-apache-bytes-average-perrequest=:10 --urlpath=/server-status-2      WARNING: BytesPerRequest: 1.25 KB | 'apache.bytes.persecond'=621568.00B;;;0; 'apache.access.persecond'=484.00;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;0:10;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      7     --warning-apache-bytes-average-persecond=400:       WARNING: avg_bytesPerSec : 10 | 'apache.bytes.persecond'=60408832.00B;;;0; 'apache.access.persecond'=474516.00;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;400:;;0;
        ...      8     --warning=400: --urlpath=/server-status-2           WARNING: RequestPerSec: 300.00 | 'apache.bytes.persecond'=621568.00B;;;0; 'apache.access.persecond'=484.00;;;0; 'apache.request.average.persecond'=300.00;400:;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      9     --critical-access=:10                               CRITICAL: AccessPerSec: 474516.00 | 'apache.bytes.persecond'=60408832.00B;;;0; 'apache.access.persecond'=474516.00;;0:10;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      10    --warning-bytes=:10 --urlpath=/server-status-2      WARNING: BytesPerSec: 607.00 KB | 'apache.bytes.persecond'=621568.00B;0:10;;0; 'apache.access.persecond'=484.00;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
