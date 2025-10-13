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
    # Check regexp instead of exact value because there can be variations with data calculation that uses the cache depending on the execution time.
    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extra_options                                       expected_result    --
        ...      1     ${EMPTY}                                            OK: bytesPerSec : Buffer creation, accessPerSec : Buffer creation, RequestPerSec: 300.00, BytesPerRequest: 2.11 MB \\\\| 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      2     --urlpath=/server-status-2                          OK: BytesPerSec: \\\\d+.\\\\d+ [KMG]?B, AccessPerSec: \\\\d+.\\\\d+, RequestPerSec: 300.00, BytesPerRequest: 1.25 KB \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      3     --urlpath=/server-status-2                          OK: BytesPerSec: \\\\d+.\\\\d+ [KMG]?B, AccessPerSec: \\\\d+.\\\\d+, RequestPerSec: 300.00, BytesPerRequest: 1.25 KB \\\\| 'apache.bytes.persecond'=0.00B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      4     --warning-apache.bytes.persecond=:400               WARNING: BytesPerSec: \\\\d+.\\\\d+ [KMG]?B \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;0:400;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      5     --critical-apache-access-persecond=:10 --urlpath=/server-status-2    CRITICAL: AccessPerSec: \\\\d+.\\\\d+ \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;0:10;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      6     --critical-apache-request-average-persecond=400:    CRITICAL: RequestPerSec: 300.00 \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;;400:;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      7     --warning-apache-bytes-average-perrequest=:10 --urlpath=/server-status-2      WARNING: BytesPerRequest: 1.25 KB \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;0:10;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      8     --warning-apache-bytes-average-persecond=400:       WARNING: avg_bytesPerSec : 10 \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;400:;;0;
        ...      9     --warning=400: --urlpath=/server-status-2           WARNING: RequestPerSec: 300.00 \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;400:;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
        ...      10     --critical-access=:10                               CRITICAL: AccessPerSec: \\\\d+.\\\\d+ \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;0:10;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=2211284.85B;;;0; 'apache.bytes.average.persecond'=10B;;;0;
        ...      11    --warning-bytes=:10 --urlpath=/server-status-2      WARNING: BytesPerSec: \\\\d+.\\\\d+ [KMG]?B \\\\| 'apache.bytes.persecond'=\\\\d+.\\\\d+B;0:10;;0; 'apache.access.persecond'=\\\\d+.\\\\d+;;;0; 'apache.request.average.persecond'=300.00;;;0; 'apache.bytes.average.perrequest'=1284.23B;;;0; 'apache.bytes.average.persecond'=100B;;;0;
