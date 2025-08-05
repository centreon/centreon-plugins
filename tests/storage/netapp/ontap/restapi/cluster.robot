*** Settings ***
Documentation       Netapp Ontap Restapi Cluster plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}netapp.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=storage::netapp::ontap::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-username=username
...                 --api-password=password
...                 --mode=cluster


*** Test Cases ***
Cluster ${tc}
    [Tags]    storage    netapp    ontapp    api    cluster    mockoon   
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${tc}    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                      expected_result    --
            ...       1   ${EMPTY}                                                           OK: cluster 'cluster1' read : Buffer creation, write : Buffer creation, other : Buffer creation, total : Buffer creation, read iops: 200, write iops: 100, other iops: 100, total iops: 1000, read latency: 200 ms, write latency: 100 ms, other latency: 100 ms, total latency: 1000 ms - node 'node-01' state: online [link status: string] | 'cluster1#cluster.io.read.usage.iops'=200iops;;;0; 'cluster1#cluster.io.write.usage.iops'=100iops;;;0; 'cluster1#cluster.io.other.usage.iops'=100iops;;;0; 'cluster1#cluster.io.total.usage.iops'=1000iops;;;0; 'cluster.io.read.latency.milliseconds'=200ms;;;0; 'cluster1#cluster.io.write.latency.milliseconds'=100ms;;;0; 'cluster.io.other.latency.milliseconds'=100ms;;;0; 'cluster1#cluster.io.total.latency.milliseconds'=1000ms;;;0;
            ...       2   ${EMPTY}                                                           OK: cluster 'cluster1' read iops: 200, write iops: 100, other iops: 100, total iops: 1000, read latency: 200 ms, write latency: 100 ms, other latency: 100 ms, total latency: 1000 ms - node 'node-01' state: online [link status: string] | 'cluster1#cluster.io.read.usage.bytespersecond'=0B/s;;;; 'cluster1#cluster.io.write.usage.bytespersecond'=0B/s;;;0; 'cluster1#cluster.io.other.usage.bytespersecond'=0B/s;;;; 'cluster1#cluster.io.total.usage.bytespersecond'=0B/s;;;0; 'cluster1#cluster.io.read.usage.iops'=200iops;;;0; 'cluster1#cluster.io.write.usage.iops'=100iops;;;0; 'cluster1#cluster.io.other.usage.iops'=100iops;;;0; 'cluster1#cluster.io.total.usage.iops'=1000iops;;;0; 'cluster.io.read.latency.milliseconds'=200ms;;;0; 'cluster1#cluster.io.write.latency.milliseconds'=100ms;;;0; 'cluster.io.other.latency.milliseconds'=100ms;;;0; 'cluster1#cluster.io.total.latency.milliseconds'=1000ms;;;0;
            ...       3   --warning-node-status='\\\%{state} !~ /notonline/i'                WARNING: cluster 'cluster1' node 'node-01' state: online [link status: string] | 'cluster1#cluster.io.read.usage.bytespersecond'=0B/s;;;; 'cluster1#cluster.io.write.usage.bytespersecond'=0B/s;;;0; 'cluster1#cluster.io.other.usage.bytespersecond'=0B/s;;;; 'cluster1#cluster.io.total.usage.bytespersecond'=0B/s;;;0; 'cluster1#cluster.io.read.usage.iops'=200iops;;;0; 'cluster1#cluster.io.write.usage.iops'=100iops;;;0; 'cluster1#cluster.io.other.usage.iops'=100iops;;;0; 'cluster1#cluster.io.total.usage.iops'=1000iops;;;0; 'cluster.io.read.latency.milliseconds'=200ms;;;0; 'cluster1#cluster.io.write.latency.milliseconds'=100ms;;;0; 'cluster.io.other.latency.milliseconds'=100ms;;;0; 'cluster1#cluster.io.total.latency.milliseconds'=1000ms;;;0;
            ...       4   --critical-node-status='\\\%{state} !~ /notonline/i'               CRITICAL: cluster 'cluster1' node 'node-01' state: online [link status: string] | 'cluster1#cluster.io.read.usage.bytespersecond'=0B/s;;;; 'cluster1#cluster.io.write.usage.bytespersecond'=0B/s;;;0; 'cluster1#cluster.io.other.usage.bytespersecond'=0B/s;;;; 'cluster1#cluster.io.total.usage.bytespersecond'=0B/s;;;0; 'cluster1#cluster.io.read.usage.iops'=200iops;;;0; 'cluster1#cluster.io.write.usage.iops'=100iops;;;0; 'cluster1#cluster.io.other.usage.iops'=100iops;;;0; 'cluster1#cluster.io.total.usage.iops'=1000iops;;;0; 'cluster.io.read.latency.milliseconds'=200ms;;;0; 'cluster1#cluster.io.write.latency.milliseconds'=100ms;;;0; 'cluster.io.other.latency.milliseconds'=100ms;;;0; 'cluster1#cluster.io.total.latency.milliseconds'=1000ms;;;0;
