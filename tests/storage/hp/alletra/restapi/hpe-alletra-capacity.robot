*** Settings ***
Documentation       HPE Alletra Storage REST API Mode Capacity

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}hpe-alletra.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::hp::alletra::restapi::plugin
...                 --mode capacity
...                 --hostname=${HOSTNAME}
...                 --api-username=xx
...                 --api-password=xx
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
Capacity ${tc}
    [Tags]    storage    api    hpe    hp
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:        tc       extraoptions                                                                                               expected_regexp    --
            ...      1        ${EMPTY}                                                                                                   OK: All storage capacities are ok | 'FCCapacity#storage.space.usage.bytes'=0B;;;0;0 'FCCapacity#storage.space.free.bytes'=0B;;;0;0 'FCCapacity#storage.space.usage.percentage'=0.00%;;;0;100 'FCCapacity#storage.space.unavailable.bytes'=0B;;;0; 'FCCapacity#storage.space.failed.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.virtualsize.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.used.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.allocated.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.free.bytes'=0B;;;0; 'FCCapacity#storage.space.compaction.ratio.count'=0;;;0; 'FCCapacity#storage.space.deduplication.ratio.count'=0;;;0; 'FCCapacity#storage.space.data_reduction.ratio.count'=0;;;0; 'FCCapacity#storage.space.overprovisioning.ratio.count'=0;;;0; 'NLCapacity#storage.space.usage.bytes'=0B;;;0;0 'NLCapacity#storage.space.free.bytes'=0B;;;0;0 'NLCapacity#storage.space.usage.percentage'=0.00%;;;0;100 'NLCapacity#storage.space.unavailable.bytes'=0B;;;0; 'NLCapacity#storage.space.failed.bytes'=0B;;;0; 'NLCapacity#storage.provisioning.virtualsize.bytes'=0B;;;0; 'NLCapacity#storage.provisioning.used.bytes'=0B;;;0; 'NLCapacity#storage.provisioning.allocated.bytes'=0B;;;0; 'NLCapacity#storage.provisioning.free.bytes'=0B;;;0; 'NLCapacity#storage.space.compaction.ratio.count'=0;;;0; 'NLCapacity#storage.space.deduplication.ratio.count'=0;;;0; 'NLCapacity#storage.space.data_reduction.ratio.count'=0;;;0; 'NLCapacity#storage.space.overprovisioning.ratio.count'=0;;;0; 'SSDCapacity#storage.space.usage.bytes'=123327838420992B;;;0;184305636605952 'SSDCapacity#storage.space.free.bytes'=60977798184960B;;;0;184305636605952 'SSDCapacity#storage.space.usage.percentage'=66.91%;;;0;100 'SSDCapacity#storage.space.unavailable.bytes'=0B;;;0; 'SSDCapacity#storage.space.failed.bytes'=0B;;;0; 'SSDCapacity#storage.provisioning.virtualsize.bytes'=145453502955520B;;;0; 'SSDCapacity#storage.provisioning.used.bytes'=98247842463744B;;;0; 'SSDCapacity#storage.provisioning.allocated.bytes'=8490068213760B;;;0; 'SSDCapacity#storage.provisioning.free.bytes'=60977798184960B;;;0; 'SSDCapacity#storage.space.compaction.ratio.count'=2.84;;;0; 'SSDCapacity#storage.space.deduplication.ratio.count'=1.17;;;0; 'SSDCapacity#storage.space.compression.ratio.count'=1;;;0; 'SSDCapacity#storage.space.data_reduction.ratio.count'=1.58;;;0; 'SSDCapacity#storage.space.overprovisioning.ratio.count'=0.87;;;0; 'allCapacity#storage.space.usage.bytes'=123327838420992B;;;0;184305636605952 'allCapacity#storage.space.free.bytes'=60977798184960B;;;0;184305636605952 'allCapacity#storage.space.usage.percentage'=66.91%;;;0;100 'allCapacity#storage.space.unavailable.bytes'=0B;;;0; 'allCapacity#storage.space.failed.bytes'=0B;;;0; 'allCapacity#storage.provisioning.virtualsize.bytes'=145453502955520B;;;0; 'allCapacity#storage.provisioning.used.bytes'=98247842463744B;;;0; 'allCapacity#storage.provisioning.allocated.bytes'=8490068213760B;;;0; 'allCapacity#storage.provisioning.free.bytes'=60977798184960B;;;0; 'allCapacity#storage.space.compaction.ratio.count'=2.84;;;0; 'allCapacity#storage.space.deduplication.ratio.count'=1.17;;;0; 'allCapacity#storage.space.compression.ratio.count'=1;;;0; 'allCapacity#storage.space.data_reduction.ratio.count'=1.58;;;0; 'allCapacity#storage.space.overprovisioning.ratio.count'=0.87;;;0;
            ...      2        --filter-type=FCCapacity                                                                                   OK: storage 'FCCapacity' space usage total: 0.00 B used: 0.00 B (0.00%) free: 0.00 B (0.00%), unavailable: 0.00 B, failed: 0.00 B - provisioning virtual size: 0.00 B, provisioning used: 0.00 B, provisioning allocated: 0.00 B, provisioning free: 0.00 B - compaction: 0, deduplication: 0, data reduction: 0, overprovisioning: 0 | 'FCCapacity#storage.space.usage.bytes'=0B;;;0;0 'FCCapacity#storage.space.free.bytes'=0B;;;0;0 'FCCapacity#storage.space.usage.percentage'=0.00%;;;0;100 'FCCapacity#storage.space.unavailable.bytes'=0B;;;0; 'FCCapacity#storage.space.failed.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.virtualsize.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.used.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.allocated.bytes'=0B;;;0; 'FCCapacity#storage.provisioning.free.bytes'=0B;;;0; 'FCCapacity#storage.space.compaction.ratio.count'=0;;;0; 'FCCapacity#storage.space.deduplication.ratio.count'=0;;;0; 'FCCapacity#storage.space.data_reduction.ratio.count'=0;;;0; 'FCCapacity#storage.space.overprovisioning.ratio.count'=0;;;0;
            ...      3        --filter-type=SSDCapacity --critical-compression=:0 --filter-counters=compression                          CRITICAL: storage 'SSDCapacity' compression: 1 | 'SSDCapacity#storage.space.compression.ratio.count'=1;;0:0;0;
            ...      4        --filter-type=SSDCapacity --filter-counters=space-usage --warning-space-usage=:160                         WARNING: storage 'SSDCapacity' space usage total: 167.62 TB used: 112.17 TB (66.91%) free: 55.46 TB (33.09%) | 'SSDCapacity#storage.space.usage.bytes'=123327838420992B;0:160;;0;184305636605952 'SSDCapacity#storage.space.free.bytes'=60977798184960B;;;0;184305636605952 'SSDCapacity#storage.space.usage.percentage'=66.91%;;;0;100
            ...      5        --filter-type=SSDCapacity --filter-counters=space-usage --critical-space-usage-free=:55                    CRITICAL: storage 'SSDCapacity' space usage total: 167.62 TB used: 112.17 TB (66.91%) free: 55.46 TB (33.09%) | 'SSDCapacity#storage.space.usage.bytes'=123327838420992B;;;0;184305636605952 'SSDCapacity#storage.space.free.bytes'=60977798184960B;;0:55;0;184305636605952 'SSDCapacity#storage.space.usage.percentage'=66.91%;;;0;100
            ...      6        --filter-type=SSDCapacity --filter-counters=space-usage --critical-space-usage-prct=:60                    CRITICAL: storage 'SSDCapacity' space usage total: 167.62 TB used: 112.17 TB (66.91%) free: 55.46 TB (33.09%) | 'SSDCapacity#storage.space.usage.bytes'=123327838420992B;;;0;184305636605952 'SSDCapacity#storage.space.free.bytes'=60977798184960B;;;0;184305636605952 'SSDCapacity#storage.space.usage.percentage'=66.91%;;0:60;0;100
            ...      7        --filter-type=SSDCapacity --filter-counters=space-unavailable --critical-space-unavailable=1:10            CRITICAL: storage 'SSDCapacity' unavailable: 0.00 B | 'SSDCapacity#storage.space.unavailable.bytes'=0B;;1:10;0;
            ...      8        --filter-type=SSDCapacity --filter-counters=space-failed --critical-space-failed=1:10                      CRITICAL: storage 'SSDCapacity' failed: 0.00 B | 'SSDCapacity#storage.space.failed.bytes'=0B;;1:10;0;
            ...      9        --filter-type=SSDCapacity --filter-counters=provisioning-virtual-size                                      OK: storage 'SSDCapacity' provisioning virtual size: 132.29 TB | 'SSDCapacity#storage.provisioning.virtualsize.bytes'=145453502955520B;;;0;
            ...      10       --filter-type=SSDCapacity --filter-counters=provisioning-used                                              OK: storage 'SSDCapacity' provisioning used: 89.36 TB | 'SSDCapacity#storage.provisioning.used.bytes'=98247842463744B;;;0;
            ...      11       --filter-type=SSDCapacity --filter-counters=provisioning-allocated --critical-provisioning-allocated=:1    CRITICAL: storage 'SSDCapacity' provisioning allocated: 7.72 TB | 'SSDCapacity#storage.provisioning.allocated.bytes'=8490068213760B;;0:1;0;
            ...      12       --filter-type=SSDCapacity --filter-counters=provisioning-free --warning-provisioning-free=:1               WARNING: storage 'SSDCapacity' provisioning free: 55.46 TB | 'SSDCapacity#storage.provisioning.free.bytes'=60977798184960B;0:1;;0;
            ...      13       --filter-type=SSDCapacity --filter-counters=compaction --warning-compaction=:1                             WARNING: storage 'SSDCapacity' compaction: 2.84 | 'SSDCapacity#storage.space.compaction.ratio.count'=2.84;0:1;;0;
            ...      14       --filter-type=SSDCapacity --filter-counters=deduplication --warning-deduplication=:1                       WARNING: storage 'SSDCapacity' deduplication: 1.17 | 'SSDCapacity#storage.space.deduplication.ratio.count'=1.17;0:1;;0;
            ...      15       --filter-type=SSDCapacity --filter-counters=data-reduction --critical-data-reduction=3:                    CRITICAL: storage 'SSDCapacity' data reduction: 1.58 | 'SSDCapacity#storage.space.data_reduction.ratio.count'=1.58;;3:;0;
            ...      16       --filter-type=SSDCapacity --filter-counters=overprovisioning                                               OK: storage 'SSDCapacity' overprovisioning: 0.87 | 'SSDCapacity#storage.space.overprovisioning.ratio.count'=0.87;;;0;
