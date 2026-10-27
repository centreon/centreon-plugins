*** Settings ***
Documentation     Storage Veritas NetBackup Appliance SSH memory

Resource          ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup       Ctn Generic Suite Setup
Suite Teardown    Ctn Generic Suite Teardown
Test Timeout      120s


*** Variables ***
${CMD}    ${CENTREON_PLUGINS}
...       --plugin=storage::veritas::nba::ssh::plugin
...       --mode=memory
...       --command=cat


*** Test Cases ***
Memory ${tc}
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
    ...    memory.txt
    ...    ${EMPTY}
    ...    OK: Ram total: 250.70 GB used (-buffers/cache): 116.91 GB (46.63%) free: 3.00 GB (1.20%) available: 131.19 GB (52.33%), buffer: 130.79 GB, shared: 138.79 MB | 'memory.usage.bytes'=125530263552B;;;0;269182509056 'memory.free.bytes'=3222704128B;;;0;269182509056 'memory.usage.percentage'=46.63%;;;0;100 'memory.available.bytes'=140865015808B;;;0;269182509056 'memory.available.percentage'=52.33%;;;0;100 'memory.buffer.bytes'=140429541376B;;;0; 'memory.shared.bytes'=145530880B;;;0;
    ...    2
    ...    memory.txt
    ...    --warning-memory-usage=100000000000
    ...    WARNING: Ram total: 250.70 GB used (-buffers/cache): 116.91 GB (46.63%) free: 3.00 GB (1.20%) available: 131.19 GB (52.33%) | 'memory.usage.bytes'=125530263552B;0:100000000000;;0;269182509056 'memory.free.bytes'=3222704128B;;;0;269182509056 'memory.usage.percentage'=46.63%;;;0;100 'memory.available.bytes'=140865015808B;;;0;269182509056 'memory.available.percentage'=52.33%;;;0;100 'memory.buffer.bytes'=140429541376B;;;0; 'memory.shared.bytes'=145530880B;;;0;
    ...    3
    ...    memory.txt
    ...    --warning-memory-usage-prct=40
    ...    WARNING: Ram total: 250.70 GB used (-buffers/cache): 116.91 GB (46.63%) free: 3.00 GB (1.20%) available: 131.19 GB (52.33%) | 'memory.usage.bytes'=125530263552B;;;0;269182509056 'memory.free.bytes'=3222704128B;;;0;269182509056 'memory.usage.percentage'=46.63%;0:40;;0;100 'memory.available.bytes'=140865015808B;;;0;269182509056 'memory.available.percentage'=52.33%;;;0;100 'memory.buffer.bytes'=140429541376B;;;0; 'memory.shared.bytes'=145530880B;;;0;
    ...    4
    ...    memory.txt
    ...    --critical-memory-usage-free=5000000000:
    ...    CRITICAL: Ram total: 250.70 GB used (-buffers/cache): 116.91 GB (46.63%) free: 3.00 GB (1.20%) available: 131.19 GB (52.33%) | 'memory.usage.bytes'=125530263552B;;;0;269182509056 'memory.free.bytes'=3222704128B;;5000000000:;0;269182509056 'memory.usage.percentage'=46.63%;;;0;100 'memory.available.bytes'=140865015808B;;;0;269182509056 'memory.available.percentage'=52.33%;;;0;100 'memory.buffer.bytes'=140429541376B;;;0; 'memory.shared.bytes'=145530880B;;;0;
    ...    5
    ...    memory.txt
    ...    --critical-memory-available=150000000000:
    ...    CRITICAL: Ram total: 250.70 GB used (-buffers/cache): 116.91 GB (46.63%) free: 3.00 GB (1.20%) available: 131.19 GB (52.33%) | 'memory.usage.bytes'=125530263552B;;;0;269182509056 'memory.free.bytes'=3222704128B;;;0;269182509056 'memory.usage.percentage'=46.63%;;;0;100 'memory.available.bytes'=140865015808B;;150000000000:;0;269182509056 'memory.available.percentage'=52.33%;;;0;100 'memory.buffer.bytes'=140429541376B;;;0; 'memory.shared.bytes'=145530880B;;;0;
    ...    6
    ...    memory.txt
    ...    --critical-memory-available-prct=60:
    ...    CRITICAL: Ram total: 250.70 GB used (-buffers/cache): 116.91 GB (46.63%) free: 3.00 GB (1.20%) available: 131.19 GB (52.33%) | 'memory.usage.bytes'=125530263552B;;;0;269182509056 'memory.free.bytes'=3222704128B;;;0;269182509056 'memory.usage.percentage'=46.63%;;;0;100 'memory.available.bytes'=140865015808B;;;0;269182509056 'memory.available.percentage'=52.33%;;60:;0;100 'memory.buffer.bytes'=140429541376B;;;0; 'memory.shared.bytes'=145530880B;;;0;
    ...    7
    ...    memory.txt
    ...    --warning-buffer=100000000000
    ...    WARNING: buffer: 130.79 GB | 'memory.usage.bytes'=125530263552B;;;0;269182509056 'memory.free.bytes'=3222704128B;;;0;269182509056 'memory.usage.percentage'=46.63%;;;0;100 'memory.available.bytes'=140865015808B;;;0;269182509056 'memory.available.percentage'=52.33%;;;0;100 'memory.buffer.bytes'=140429541376B;0:100000000000;;0; 'memory.shared.bytes'=145530880B;;;0;
    ...    8
    ...    memory.txt
    ...    --critical-shared=100000000
    ...    CRITICAL: shared: 138.79 MB | 'memory.usage.bytes'=125530263552B;;;0;269182509056 'memory.free.bytes'=3222704128B;;;0;269182509056 'memory.usage.percentage'=46.63%;;;0;100 'memory.available.bytes'=140865015808B;;;0;269182509056 'memory.available.percentage'=52.33%;;;0;100 'memory.buffer.bytes'=140429541376B;;;0; 'memory.shared.bytes'=145530880B;;0:100000000;0;
    ...    9
    ...    memory.txt
    ...    --filter-counters=shared
    ...    OK: shared: 138.79 MB | 'memory.shared.bytes'=145530880B;;;0;
    ...    10
    ...    storage.txt
    ...    ${EMPTY}
    ...    UNKNOWN: Cannot find memory information in the output
