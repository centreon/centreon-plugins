*** Settings ***
Documentation       Cloud Linux Libvirt Pool Status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=cloud::linux::libvirt::local::plugin
...                 --custommode=virshcli
...                 --virsh-path=${CURDIR}${/}virsh_bin
...                 --mode=pool-status


*** Test Cases ***
Pool Status ${tc}
    [Documentation]    Check storage pool status and usage
    [Tags]    cloud    linux    libvirt    pool-status

    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extra_options                                             expected_result    --
        ...      1     ${EMPTY}                                                  OK: All storage pools are ok | 'default#pool.space.usage.bytes'=26843545600B;;;0;107374182400 'default#pool.space.usage.percentage'=25.00%;;;0;100 'default#pool.space.free.bytes'=80530636800B;;;0; 'pool1#pool.space.usage.bytes'=10737418240B;;;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;;;0;100 'pool1#pool.space.free.bytes'=42949672960B;;;0;
        ...      2     --pool-name=default                                       OK: Pool 'default' state is 'running' [autostart: yes], space used: 25.00 GB / 100.00 GB (25.00 %), space used: 25.00 %, space free: 75.00 GB | 'default#pool.space.usage.bytes'=26843545600B;;;0;107374182400 'default#pool.space.usage.percentage'=25.00%;;;0;100 'default#pool.space.free.bytes'=80530636800B;;;0;
        ...      3     --pool-name=pool1                                         OK: Pool 'pool1' state is 'running' [autostart: no], space used: 10.00 GB / 50.00 GB (20.00 %), space used: 20.00 %, space free: 40.00 GB | 'pool1#pool.space.usage.bytes'=10737418240B;;;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;;;0;100 'pool1#pool.space.free.bytes'=42949672960B;;;0;
        ...      4     --pool-name=pool1 --warning-space-usage=5000000000        WARNING: Pool 'pool1' space used: 10.00 GB / 50.00 GB (20.00 %) | 'pool1#pool.space.usage.bytes'=10737418240B;0:5000000000;;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;;;0;100 'pool1#pool.space.free.bytes'=42949672960B;;;0;
        ...      5     --pool-name=pool1 --critical-space-usage=5000000000       CRITICAL: Pool 'pool1' space used: 10.00 GB / 50.00 GB (20.00 %) | 'pool1#pool.space.usage.bytes'=10737418240B;;0:5000000000;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;;;0;100 'pool1#pool.space.free.bytes'=42949672960B;;;0;
        ...      6     --pool-name=pool1 --warning-space-usage-prct=10           WARNING: Pool 'pool1' space used: 20.00 % | 'pool1#pool.space.usage.bytes'=10737418240B;;;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;0:10;;0;100 'pool1#pool.space.free.bytes'=42949672960B;;;0;
        ...      7     --pool-name=pool1 --critical-space-usage-prct=15          CRITICAL: Pool 'pool1' space used: 20.00 % | 'pool1#pool.space.usage.bytes'=10737418240B;;;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;;0:15;0;100 'pool1#pool.space.free.bytes'=42949672960B;;;0;
        ...      8     --pool-name=pool1 --warning-space-free=30000000000        WARNING: Pool 'pool1' space free: 40.00 GB | 'pool1#pool.space.usage.bytes'=10737418240B;;;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;;;0;100 'pool1#pool.space.free.bytes'=42949672960B;0:30000000000;;0;
        ...      9     --pool-name=pool1 --critical-space-free=30000000000       CRITICAL: Pool 'pool1' space free: 40.00 GB | 'pool1#pool.space.usage.bytes'=10737418240B;;;0;53687091200 'pool1#pool.space.usage.percentage'=20.00%;;;0;100 'pool1#pool.space.free.bytes'=42949672960B;;0:30000000000;0;
