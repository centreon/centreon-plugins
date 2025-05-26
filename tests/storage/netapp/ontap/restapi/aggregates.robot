*** Settings ***
Documentation       Netapp Ontap Restapi Aggregates plugin

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
...                 --mode=aggregates


*** Test Cases ***
Aggregates ${tc}
    [Tags]    storage    netapp    ontapp    api    aggregates    mockoon   
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                                      expected_result    --
            ...       1   ${EMPTY}                                                           OK: Aggregates 'aggregate1' state: online, space usage total: 9.46 GB used: 1.99 MB (0.02%) free: 9.46 GB (100.00%), read iops: 500, write iops: 200, other iops: 100, total iops: 1000, read latency: 500 µs, write latency: 200 µs, other latency: 100 µs, total latency: 1000 µs | 'aggregate1#aggregate.space.usage.bytes'=2088960B;;;0;10156769280 'aggregate1#aggregate.space.free.bytes'=10156560384B;;;0;10156769280 'aggregate1#aggregate.space.usage.percentage'=0.02%;;;0;100 'aggregate1#aggregate.io.read.usage.bytespersecond'=500B/s;;;; 'aggregate1#aggregate.io.write.usage.bytespersecond'=200B/s;;;0; 'aggregate1#aggregate.io.other.usage.bytespersecond'=100B/s;;;0; 'aggregate1#aggregate.io.total.usage.bytespersecond'=1000B/s;;;0; 'aggregate1#aggregate.io.read.usage.iops'=500iops;;;0; 'aggregate1#aggregate.io.write.usage.iops'=200iops;;;0; 'aggregate1#aggregate.io.other.usage.iops'=100iops;;;0; 'aggregate1#aggregate.io.total.usage.iops'=1000iops;;;0; 'aggregate1#aggregate.io.read.latency.microseconds'=500µs;;;0; 'aggregate1#aggregate.io.write.latency.microseconds'=200µs;;;0; 'aggregate1#aggregate.io.other.latency.microseconds'=100µs;;;0; 'aggregate1#aggregate.io.total.latency.microseconds'=1000µs;;;0;
            ...       2   --warning-status='\\\%{state} !~ /notonline/i'                     WARNING: Aggregates 'aggregate1' state: online | 'aggregate1#aggregate.space.usage.bytes'=2088960B;;;0;10156769280 'aggregate1#aggregate.space.free.bytes'=10156560384B;;;0;10156769280 'aggregate1#aggregate.space.usage.percentage'=0.02%;;;0;100 'aggregate1#aggregate.io.read.usage.bytespersecond'=500B/s;;;; 'aggregate1#aggregate.io.write.usage.bytespersecond'=200B/s;;;0; 'aggregate1#aggregate.io.other.usage.bytespersecond'=100B/s;;;0; 'aggregate1#aggregate.io.total.usage.bytespersecond'=1000B/s;;;0; 'aggregate1#aggregate.io.read.usage.iops'=500iops;;;0; 'aggregate1#aggregate.io.write.usage.iops'=200iops;;;0; 'aggregate1#aggregate.io.other.usage.iops'=100iops;;;0; 'aggregate1#aggregate.io.total.usage.iops'=1000iops;;;0; 'aggregate1#aggregate.io.read.latency.microseconds'=500µs;;;0; 'aggregate1#aggregate.io.write.latency.microseconds'=200µs;;;0; 'aggregate1#aggregate.io.other.latency.microseconds'=100µs;;;0; 'aggregate1#aggregate.io.total.latency.microseconds'=1000µs;;;0;
            ...       3   --critical-status='\\\%{state} !~ /notonline/i'                    CRITICAL: Aggregates 'aggregate1' state: online | 'aggregate1#aggregate.space.usage.bytes'=2088960B;;;0;10156769280 'aggregate1#aggregate.space.free.bytes'=10156560384B;;;0;10156769280 'aggregate1#aggregate.space.usage.percentage'=0.02%;;;0;100 'aggregate1#aggregate.io.read.usage.bytespersecond'=500B/s;;;; 'aggregate1#aggregate.io.write.usage.bytespersecond'=200B/s;;;0; 'aggregate1#aggregate.io.other.usage.bytespersecond'=100B/s;;;0; 'aggregate1#aggregate.io.total.usage.bytespersecond'=1000B/s;;;0; 'aggregate1#aggregate.io.read.usage.iops'=500iops;;;0; 'aggregate1#aggregate.io.write.usage.iops'=200iops;;;0; 'aggregate1#aggregate.io.other.usage.iops'=100iops;;;0; 'aggregate1#aggregate.io.total.usage.iops'=1000iops;;;0; 'aggregate1#aggregate.io.read.latency.microseconds'=500µs;;;0; 'aggregate1#aggregate.io.write.latency.microseconds'=200µs;;;0; 'aggregate1#aggregate.io.other.latency.microseconds'=100µs;;;0; 'aggregate1#aggregate.io.total.latency.microseconds'=1000µs;;;0;
            ...       6   --warning-usage-prct=50:50                                         WARNING: Aggregates 'aggregate1' used : 0.02 % | 'aggregate1#aggregate.space.usage.bytes'=2088960B;;;0;10156769280 'aggregate1#aggregate.space.free.bytes'=10156560384B;;;0;10156769280 'aggregate1#aggregate.space.usage.percentage'=0.02%;50:50;;0;100 'aggregate1#aggregate.io.read.usage.bytespersecond'=500B/s;;;; 'aggregate1#aggregate.io.write.usage.bytespersecond'=200B/s;;;0; 'aggregate1#aggregate.io.other.usage.bytespersecond'=100B/s;;;0; 'aggregate1#aggregate.io.total.usage.bytespersecond'=1000B/s;;;0; 'aggregate1#aggregate.io.read.usage.iops'=500iops;;;0; 'aggregate1#aggregate.io.write.usage.iops'=200iops;;;0; 'aggregate1#aggregate.io.other.usage.iops'=100iops;;;0; 'aggregate1#aggregate.io.total.usage.iops'=1000iops;;;0; 'aggregate1#aggregate.io.read.latency.microseconds'=500µs;;;0; 'aggregate1#aggregate.io.write.latency.microseconds'=200µs;;;0; 'aggregate1#aggregate.io.other.latency.microseconds'=100µs;;;0; 'aggregate1#aggregate.io.total.latency.microseconds'=1000µs;;;0;
            ...       7   --critical-usage-prct=50:50                                        CRITICAL: Aggregates 'aggregate1' used : 0.02 % | 'aggregate1#aggregate.space.usage.bytes'=2088960B;;;0;10156769280 'aggregate1#aggregate.space.free.bytes'=10156560384B;;;0;10156769280 'aggregate1#aggregate.space.usage.percentage'=0.02%;;50:50;0;100 'aggregate1#aggregate.io.read.usage.bytespersecond'=500B/s;;;; 'aggregate1#aggregate.io.write.usage.bytespersecond'=200B/s;;;0; 'aggregate1#aggregate.io.other.usage.bytespersecond'=100B/s;;;0; 'aggregate1#aggregate.io.total.usage.bytespersecond'=1000B/s;;;0; 'aggregate1#aggregate.io.read.usage.iops'=500iops;;;0; 'aggregate1#aggregate.io.write.usage.iops'=200iops;;;0; 'aggregate1#aggregate.io.other.usage.iops'=100iops;;;0; 'aggregate1#aggregate.io.total.usage.iops'=1000iops;;;0; 'aggregate1#aggregate.io.read.latency.microseconds'=500µs;;;0; 'aggregate1#aggregate.io.write.latency.microseconds'=200µs;;;0; 'aggregate1#aggregate.io.other.latency.microseconds'=100µs;;;0; 'aggregate1#aggregate.io.total.latency.microseconds'=1000µs;;;0;