*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::ibm::flashsystem::restapi::plugin
...                 --mode=performance
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --port=${APIPORT}
...                 --api-path='/rest/v1'
...                 --api-username='user'
...                 --api-password='pass'
...                 --statefile-dir=/tmp


*** Test Cases ***
performance ${tc}
    [Tags]    storage    ibm    flashsystem    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                 expected_result    --
            ...       1       ${EMPTY}                                                      OK: Performance: latency 0.398 ms, read 0.341 ms, write 0.472 ms, 7923 IOPS, bandwidth 408.00 MB/s, cpu 15 %, compression cpu 0 %, write cache 34 %, total cache 80 %, backend 0.314 ms, drives 0.194 ms, fc 29503 IOPS, fc 546.00 MB/s - All node CPUs are ok | 'system.io.latency.milliseconds'=0.398ms;;;0; 'system.io.read.latency.milliseconds'=0.341ms;;;0; 'system.io.write.latency.milliseconds'=0.472ms;;;0; 'system.io.usage.iops'=7923iops;;;0; 'system.io.usage.bytespersecond'=427819008B/s;;;0; 'system.cpu.utilization.percentage'=15%;;;0;100 'system.cpu.compression.utilization.percentage'=0%;;;0;100 'system.cache.write.usage.percentage'=34%;;;0;100 'system.cache.total.usage.percentage'=80%;;;0;100 'system.backend.latency.milliseconds'=0.314ms;;;0; 'system.drive.latency.milliseconds'=0.194ms;;;0; 'system.fc.usage.iops'=29503iops;;;0; 'system.fc.usage.bytespersecond'=572522496B/s;;;0; 'node1#node.cpu.utilization.percentage'=15%;;;0;100 'node2#node.cpu.utilization.percentage'=15%;;;0;100
            ...       2       --filter-counters='latency'                                   OK: Performance: latency 0.398 ms, read 0.341 ms, write 0.472 ms, backend 0.314 ms, drives 0.194 ms | 'system.io.latency.milliseconds'=0.398ms;;;0; 'system.io.read.latency.milliseconds'=0.341ms;;;0; 'system.io.write.latency.milliseconds'=0.472ms;;;0; 'system.backend.latency.milliseconds'=0.314ms;;;0; 'system.drive.latency.milliseconds'=0.194ms;;;0;
            ...       3       --filter-counters='cpu' --warning-cpu=10 --critical-cpu=90    WARNING: Performance: cpu 15 % | 'system.cpu.utilization.percentage'=15%;0:10;0:90;0;100 'system.cpu.compression.utilization.percentage'=0%;;;0;100 'node1#node.cpu.utilization.percentage'=15%;;;0;100 'node2#node.cpu.utilization.percentage'=15%;;;0;100
            ...       4       --filter-counters='iops|bandwidth|cache'                      OK: Performance: 7923 IOPS, bandwidth 408.00 MB/s, write cache 34 %, total cache 80 %, fc 29503 IOPS, fc 546.00 MB/s | 'system.io.usage.iops'=7923iops;;;0; 'system.io.usage.bytespersecond'=427819008B/s;;;0; 'system.cache.write.usage.percentage'=34%;;;0;100 'system.cache.total.usage.percentage'=80%;;;0;100 'system.fc.usage.iops'=29503iops;;;0; 'system.fc.usage.bytespersecond'=572522496B/s;;;0;
            ...       5       --add-peaks                                                   OK: Performance: latency 0.398 ms, read 0.341 ms, write 0.472 ms, 7923 IOPS, bandwidth 408.00 MB/s, cpu 15 %, compression cpu 0 %, write cache 34 %, total cache 80 %, backend 0.314 ms, drives 0.194 ms, fc 29503 IOPS, fc 546.00 MB/s - All node CPUs are ok | 'system.io.latency.milliseconds'=0.398ms;;;0; 'system.io.read.latency.milliseconds'=0.341ms;;;0; 'system.io.write.latency.milliseconds'=0.472ms;;;0; 'system.io.usage.iops'=7923iops;;;0; 'system.io.usage.bytespersecond'=427819008B/s;;;0; 'system.cpu.utilization.percentage'=15%;;;0;100 'system.cpu.compression.utilization.percentage'=0%;;;0;100 'system.cache.write.usage.percentage'=34%;;;0;100 'system.cache.total.usage.percentage'=80%;;;0;100 'system.backend.latency.milliseconds'=0.314ms;;;0; 'system.drive.latency.milliseconds'=0.194ms;;;0; 'system.fc.usage.iops'=29503iops;;;0; 'system.fc.usage.bytespersecond'=572522496B/s;;;0; 'node1#node.cpu.utilization.percentage'=15%;;;0;100 'node2#node.cpu.utilization.percentage'=15%;;;0;100
