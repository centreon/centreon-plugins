*** Settings ***
Documentation     Storage Veritas NetBackup Appliance SSH storage

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS}
...       --plugin=storage::veritas::nba::ssh::plugin
...       --mode=storage
...       --command=cat


*** Test Cases ***
Storage ${tc}
    [Tags]    storage    veritas    ssh
    ${command}    Catenate
    ...    ${CMD}
    ...    --command-options=${CURDIR}${/}${fixture}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    fixture
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    storage.txt
    ...    ${EMPTY}
    ...    OK: All partitions are ok | 'Configuration#partition.space.usage.bytes'=1460288880B;;;0;107374182400 'Configuration#partition.space.free.bytes'=105913893519B;;;0;107374182400 'Configuration#partition.space.usage.percentage'=1.36%;;;0;100 'MSDP#partition.space.usage.bytes'=187477727652085B;;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;;;0;100 'MSDP Catalog#partition.space.usage.bytes'=9932111872B;;;0;856845975552 'MSDP Catalog#partition.space.free.bytes'=846913863680B;;;0;856845975552 'MSDP Catalog#partition.space.usage.percentage'=1.16%;;;0;100 'NDMP Log#partition.space.usage.bytes'=123931281326B;;;0;805306368000 'NDMP Log#partition.space.free.bytes'=681375086673B;;;0;805306368000 'NDMP Log#partition.space.usage.percentage'=15.39%;;;0;100
    ...    2
    ...    storage.txt
    ...    --warning-space-usage-prct=60
    ...    WARNING: Partition 'MSDP' space usage total: 251.00 TB used: 170.51 TB (67.93%) free: 80.49 TB (32.07%) | 'Configuration#partition.space.usage.bytes'=1460288880B;;;0;107374182400 'Configuration#partition.space.free.bytes'=105913893519B;;;0;107374182400 'Configuration#partition.space.usage.percentage'=1.36%;0:60;;0;100 'MSDP#partition.space.usage.bytes'=187477727652085B;;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;0:60;;0;100 'MSDP Catalog#partition.space.usage.bytes'=9932111872B;;;0;856845975552 'MSDP Catalog#partition.space.free.bytes'=846913863680B;;;0;856845975552 'MSDP Catalog#partition.space.usage.percentage'=1.16%;0:60;;0;100 'NDMP Log#partition.space.usage.bytes'=123931281326B;;;0;805306368000 'NDMP Log#partition.space.free.bytes'=681375086673B;;;0;805306368000 'NDMP Log#partition.space.usage.percentage'=15.39%;0:60;;0;100
    ...    3
    ...    storage.txt
    ...    --warning-space-usage=180000000000000
    ...    WARNING: Partition 'MSDP' space usage total: 251.00 TB used: 170.51 TB (67.93%) free: 80.49 TB (32.07%) | 'Configuration#partition.space.usage.bytes'=1460288880B;0:180000000000000;;0;107374182400 'Configuration#partition.space.free.bytes'=105913893519B;;;0;107374182400 'Configuration#partition.space.usage.percentage'=1.36%;;;0;100 'MSDP#partition.space.usage.bytes'=187477727652085B;0:180000000000000;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;;;0;100 'MSDP Catalog#partition.space.usage.bytes'=9932111872B;0:180000000000000;;0;856845975552 'MSDP Catalog#partition.space.free.bytes'=846913863680B;;;0;856845975552 'MSDP Catalog#partition.space.usage.percentage'=1.16%;;;0;100 'NDMP Log#partition.space.usage.bytes'=123931281326B;0:180000000000000;;0;805306368000 'NDMP Log#partition.space.free.bytes'=681375086673B;;;0;805306368000 'NDMP Log#partition.space.usage.percentage'=15.39%;;;0;100
    ...    4
    ...    storage.txt
    ...    --critical-space-usage-free=110000000000:
    ...    CRITICAL: Partition 'Configuration' space usage total: 100.00 GB used: 1.36 GB (1.36%) free: 98.64 GB (98.64%) | 'Configuration#partition.space.usage.bytes'=1460288880B;;;0;107374182400 'Configuration#partition.space.free.bytes'=105913893519B;;110000000000:;0;107374182400 'Configuration#partition.space.usage.percentage'=1.36%;;;0;100 'MSDP#partition.space.usage.bytes'=187477727652085B;;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;110000000000:;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;;;0;100 'MSDP Catalog#partition.space.usage.bytes'=9932111872B;;;0;856845975552 'MSDP Catalog#partition.space.free.bytes'=846913863680B;;110000000000:;0;856845975552 'MSDP Catalog#partition.space.usage.percentage'=1.16%;;;0;100 'NDMP Log#partition.space.usage.bytes'=123931281326B;;;0;805306368000 'NDMP Log#partition.space.free.bytes'=681375086673B;;110000000000:;0;805306368000 'NDMP Log#partition.space.usage.percentage'=15.39%;;;0;100
    ...    5
    ...    storage.txt
    ...    --filter-counters=status
    ...    OK: All partitions are ok
    ...    6
    ...    storage.txt
    ...    --include-name='^MSDP$'
    ...    OK: Partition 'MSDP' status: Optimal, space usage total: 251.00 TB used: 170.51 TB (67.93%) free: 80.49 TB (32.07%) | 'MSDP#partition.space.usage.bytes'=187477727652085B;;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;;;0;100
    ...    7
    ...    storage.txt
    ...    --exclude-name='MSDP|NDMP|Configuration'
    ...    OK: All partitions are ok
    ...    8
    ...    storage.txt
    ...    --include-name=unknown
    ...    UNKNOWN: No partition found. Please check filters.
    ...    9
    ...    storage.txt
    ...    --critical-status='\\\%{name} eq "Share"'
    ...    CRITICAL: Partition 'Share' status: Not Configured | 'Configuration#partition.space.usage.bytes'=1460288880B;;;0;107374182400 'Configuration#partition.space.free.bytes'=105913893519B;;;0;107374182400 'Configuration#partition.space.usage.percentage'=1.36%;;;0;100 'MSDP#partition.space.usage.bytes'=187477727652085B;;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;;;0;100 'MSDP Catalog#partition.space.usage.bytes'=9932111872B;;;0;856845975552 'MSDP Catalog#partition.space.free.bytes'=846913863680B;;;0;856845975552 'MSDP Catalog#partition.space.usage.percentage'=1.16%;;;0;100 'NDMP Log#partition.space.usage.bytes'=123931281326B;;;0;805306368000 'NDMP Log#partition.space.free.bytes'=681375086673B;;;0;805306368000 'NDMP Log#partition.space.usage.percentage'=15.39%;;;0;100
    ...    10
    ...    storage-degraded.txt
    ...    ${EMPTY}
    ...    CRITICAL: Partition 'Configuration' status: Not Accessible WARNING: Partition 'MSDP' status: Degraded | 'Configuration#partition.space.usage.bytes'=1460288880B;;;0;107374182400 'Configuration#partition.space.free.bytes'=105913893519B;;;0;107374182400 'Configuration#partition.space.usage.percentage'=1.36%;;;0;100 'MSDP#partition.space.usage.bytes'=187477727652085B;;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;;;0;100 'MSDP Catalog#partition.space.usage.bytes'=9932111872B;;;0;856845975552 'MSDP Catalog#partition.space.free.bytes'=846913863680B;;;0;856845975552 'MSDP Catalog#partition.space.usage.percentage'=1.16%;;;0;100 'NDMP Log#partition.space.usage.bytes'=123931281326B;;;0;805306368000 'NDMP Log#partition.space.free.bytes'=681375086673B;;;0;805306368000 'NDMP Log#partition.space.usage.percentage'=15.39%;;;0;100
    ...    11
    ...    storage-degraded.txt
    ...    --critical-status='\\\%{status} !~ /Optimal|Not Configured/'
    ...    CRITICAL: Partition 'Configuration' status: Not Accessible - Partition 'MSDP' status: Degraded - Partition 'MSDP Catalog' status: Failed | 'Configuration#partition.space.usage.bytes'=1460288880B;;;0;107374182400 'Configuration#partition.space.free.bytes'=105913893519B;;;0;107374182400 'Configuration#partition.space.usage.percentage'=1.36%;;;0;100 'MSDP#partition.space.usage.bytes'=187477727652085B;;;0;275977418571776 'MSDP#partition.space.free.bytes'=88499690919690B;;;0;275977418571776 'MSDP#partition.space.usage.percentage'=67.93%;;;0;100 'MSDP Catalog#partition.space.usage.bytes'=9932111872B;;;0;856845975552 'MSDP Catalog#partition.space.free.bytes'=846913863680B;;;0;856845975552 'MSDP Catalog#partition.space.usage.percentage'=1.16%;;;0;100 'NDMP Log#partition.space.usage.bytes'=123931281326B;;;0;805306368000 'NDMP Log#partition.space.free.bytes'=681375086673B;;;0;805306368000 'NDMP Log#partition.space.usage.percentage'=15.39%;;;0;100
    ...    12
    ...    memory.txt
    ...    ${EMPTY}
    ...    UNKNOWN: Cannot find the partition summary table in the output

Storage discovery ${tc}
    [Tags]    storage    veritas    ssh
    ${command}    Catenate
    ...    ${CMD}
    ...    --command-options=${CURDIR}${/}${fixture}
    ...    ${extraoptions}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    fixture
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    storage.txt
    ...    --disco-format
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <element>name</element> <element>status</element> </data>
    ...    2
    ...    storage.txt
    ...    --disco-show
    ...    <?xml version="1.0" encoding="utf-8"?> <data> <label name="AdvancedDisk" status="Not Configured"/> <label name="CDPGateway" status="Not Configured"/> <label name="Configuration" status="Optimal"/> <label name="MSDP" status="Optimal"/> <label name="MSDP Catalog" status="Optimal"/> <label name="NDMP Log" status="Optimal"/> <label name="Share" status="Not Configured"/> </data>
