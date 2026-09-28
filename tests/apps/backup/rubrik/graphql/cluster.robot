*** Settings ***
Documentation       apps::backup::rubrik::graphql::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}rubrik-mockoon.json
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::rubrik::graphql::plugin
...                 --mode=cluster
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --service-account=XXX
...                 --secret=XXX


*** Test Cases ***
Cluster ${tc}
    [Tags]    apps    backup    graphql
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
    ...    OK: All clusters are ok | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    2
    ...    --start-time=2020-01-01 --end-time=2030-02-02
    ...    OK: All clusters are ok | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    3
    ...    --include-cluster=TEST-D2
    ...    OK: Cluster 'TEST-D2' status: connected, system status: ok, is healthy: true, IPMI: Https+Ikvm | 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    4
    ...    --last=99999m
    ...    OK: All clusters are ok | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    5
    ...    --warning-status=1
    ...    WARNING: Cluster 'TEST-D1' status: connected, system status: ok, is healthy: true, IPMI: Https+Ikvm - Cluster 'TEST-D2' status: connected, system status: ok, is healthy: true, IPMI: Https+Ikvm | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    6
    ...    --critical-status=1
    ...    CRITICAL: Cluster 'TEST-D1' status: connected, system status: ok, is healthy: true, IPMI: Https+Ikvm - Cluster 'TEST-D2' status: connected, system status: ok, is healthy: true, IPMI: Https+Ikvm | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    7
    ...    --warning-read=1
    ...    WARNING: Cluster 'TEST-D1' read: 39.88 KB/s - Cluster 'TEST-D2' read: 39.88 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;0:1;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;0:1;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    8
    ...    --critical-read=1
    ...    CRITICAL: Cluster 'TEST-D1' read: 39.88 KB/s - Cluster 'TEST-D2' read: 39.88 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;0:1;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;0:1;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    9
    ...    --warning-write=1
    ...    WARNING: Cluster 'TEST-D1' write: 740.96 KB/s - Cluster 'TEST-D2' write: 740.96 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;0:1;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;0:1;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    10
    ...    --critical-write=1
    ...    CRITICAL: Cluster 'TEST-D1' write: 740.96 KB/s - Cluster 'TEST-D2' write: 740.96 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;0:1;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;0:1;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    11
    ...    --warning-read-iops=1
    ...    WARNING: Cluster 'TEST-D1' read iops: 1.67 - Cluster 'TEST-D2' read iops: 1.67 | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;0:1;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;0:1;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    12
    ...    --critical-read-iops=1
    ...    CRITICAL: Cluster 'TEST-D1' read iops: 1.67 - Cluster 'TEST-D2' read iops: 1.67 | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;0:1;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;0:1;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    13
    ...    --warning-write-iops=1
    ...    WARNING: Cluster 'TEST-D1' write iops: 69.83 - Cluster 'TEST-D2' write iops: 69.83 | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;0:1;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;0:1;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    14
    ...    --critical-write-iops=1
    ...    CRITICAL: Cluster 'TEST-D1' write iops: 69.83 - Cluster 'TEST-D2' write iops: 69.83 | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;0:1;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;0:1;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    15
    ...    --warning-received=1
    ...    WARNING: Cluster 'TEST-D1' received: 1.97 KB/s - Cluster 'TEST-D2' received: 1.97 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;0:1;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;0:1;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    16
    ...    --critical-received=1
    ...    CRITICAL: Cluster 'TEST-D1' received: 1.97 KB/s - Cluster 'TEST-D2' received: 1.97 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;0:1;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;0:1;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
    ...    17
    ...    --warning-transmitted=1
    ...    WARNING: Cluster 'TEST-D1' transmitted: 6.70 KB/s - Cluster 'TEST-D2' transmitted: 6.70 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;0:1;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;0:1;;0;
    ...    18
    ...    --critical-transmitted=1
    ...    CRITICAL: Cluster 'TEST-D1' transmitted: 6.70 KB/s - Cluster 'TEST-D2' transmitted: 6.70 KB/s | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;0:1;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;0:1;0;
    ...    19
    ...    --exclude-cluster=abcdeff-xwxwxwxw-xwxwxw-xwxwxw-xwxwxw
    ...    OK: All clusters are ok | 'TEST-D1#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D1#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D1#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D1#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D1#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D1#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0; 'TEST-D2#cluster.io.read.usage.bytespersecond'=40834B/s;;;; 'TEST-D2#cluster.io.write.usage.bytespersecond'=758740B/s;;;0; 'TEST-D2#cluster.io.read.usage.iops'=1.67iops;;;0; 'TEST-D2#cluster.io.write.usage.iops'=69.83iops;;;0; 'TEST-D2#cluster.network.received.usage.bytespersecond'=2018B/s;;;; 'TEST-D2#cluster.network.transmitted.usage.bytespersecond'=6857B/s;;;0;
