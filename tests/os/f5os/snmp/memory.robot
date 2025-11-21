*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::f5os::snmp::plugin


*** Test Cases ***
memory ${tc}
    [Tags]    os    f5os    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/f5os/snmp/f5os
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                    expected_result    --
            ...      1     ${EMPTY}                                                                         OK: Memory total: 15.00 GB used: 6.60 GB (43.99%) free: 8.40 GB (56.01%) | 'memory.usage.bytes'=7085105152B;;;0;16107667456 'memory.free.bytes'=9022562304B;;;0;16107667456 'memory.usage.percent'=43.99%;;;0;100 'memory.free.percent'=56.01%;;;0;100
            ...      2     --warning-usage=:5GB                                                             WARNING: Memory total: 15.00 GB used: 6.60 GB (43.99%) free: 8.40 GB (56.01%) | 'memory.usage.bytes'=7085105152B;0:5368709120;;0;16107667456 'memory.free.bytes'=9022562304B;;;0;16107667456 'memory.usage.percent'=43.99%;;;0;100 'memory.free.percent'=56.01%;;;0;100
            ...      3     --critical-free=:6GB                                                             CRITICAL: Memory total: 15.00 GB used: 6.60 GB (43.99%) free: 8.40 GB (56.01%) | 'memory.usage.bytes'=7085105152B;;;0;16107667456 'memory.free.bytes'=9022562304B;;0:6442450944;0;16107667456 'memory.usage.percent'=43.99%;;;0;100 'memory.free.percent'=56.01%;;;0;100
            ...      4     --critical-usage-prct=40                                                         CRITICAL: Memory total: 15.00 GB used: 6.60 GB (43.99%) free: 8.40 GB (56.01%) | 'memory.usage.bytes'=7085105152B;;;0;16107667456 'memory.free.bytes'=9022562304B;;;0;16107667456 'memory.usage.percent'=43.99%;;0:40;0;100 'memory.free.percent'=56.01%;;;0;100
            ...      5     --warning-free-prct=60:                                                          WARNING: Memory total: 15.00 GB used: 6.60 GB (43.99%) free: 8.40 GB (56.01%) | 'memory.usage.bytes'=7085105152B;;;0;16107667456 'memory.free.bytes'=9022562304B;;;0;16107667456 'memory.usage.percent'=43.99%;;;0;100 'memory.free.percent'=56.01%;60:;;0;100
