*** Settings ***
Documentation       Network Teldat SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                          ${CENTREON_PLUGINS} --plugin=network::teldat::snmp::plugin

# Test simple usage of the CPU mode
&{teldat_cpu_test1}
...                             warningcpuutilization5s=
...                             criticalcpuutilization5s=
...                             warningcpuutilization1m=
...                             criticalcpuutilization1m=
...                             warningcpuutilization5m=
...                             criticalcpuutilization5m=
...                             result=OK: cpu average usage: 1.00 % (5s), 1.00 % (1m), 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100

# Test CPU mode with warning-cpu-utilization-5s option set to a 0.5
&{teldat_cpu_test2}
...                             warningcpuutilization5s=0.5
...                             criticalcpuutilization5s=
...                             warningcpuutilization1m=
...                             criticalcpuutilization1m=
...                             warningcpuutilization5m=
...                             criticalcpuutilization5m=
...                             result=WARNING: cpu average usage: 1.00 % (5s) | 'cpu.utilization.5s.percentage'=1.00%;0:0.5;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100

# Test CPU mode with critical-cpu-utilization-5s option set to a 0.5
&{teldat_cpu_test3}
...                             warningcpuutilization5s=
...                             criticalcpuutilization5s=0.5
...                             warningcpuutilization1m=
...                             criticalcpuutilization1m=
...                             warningcpuutilization5m=
...                             criticalcpuutilization5m=
...                             result=CRITICAL: cpu average usage: 1.00 % (5s) | 'cpu.utilization.5s.percentage'=1.00%;;0:0.5;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100

# Test CPU mode with warning-cpu-utilization-1m option set to a 0.5
&{teldat_cpu_test4}
...                             warningcpuutilization5s=
...                             criticalcpuutilization5s=
...                             warningcpuutilization1m=0.5
...                             criticalcpuutilization1m=
...                             warningcpuutilization5m=
...                             criticalcpuutilization5m=
...                             result=WARNING: cpu average usage: 1.00 % (1m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;0:0.5;;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100

# Test CPU mode with critical-cpu-utilization-1m option set to a 0.5
&{teldat_cpu_test5}
...                             warningcpuutilization5s=
...                             criticalcpuutilization5s=
...                             warningcpuutilization1m=
...                             criticalcpuutilization1m=0.5
...                             warningcpuutilization5m=
...                             criticalcpuutilization5m=
...                             result=CRITICAL: cpu average usage: 1.00 % (1m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;0:0.5;0;100 'cpu.utilization.15m.percentage'=1.00%;;;0;100

# Test CPU mode with warning-cpu-utilization-5m option set to a 0.5
&{teldat_cpu_test6}
...                             warningcpuutilization5s=
...                             criticalcpuutilization5s=
...                             warningcpuutilization1m=
...                             criticalcpuutilization1m=
...                             warningcpuutilization5m=0.5
...                             criticalcpuutilization5m=
...                             result=WARNING: cpu average usage: 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;0:0.5;;0;100

# Test CPU mode with critical-cpu-utilization-5m option set to a 0.5
&{teldat_cpu_test7}
...                             warningcpuutilization5s=
...                             criticalcpuutilization5s=
...                             warningcpuutilization1m=
...                             criticalcpuutilization1m=
...                             warningcpuutilization5m=
...                             criticalcpuutilization5m=0.5
...                             result=CRITICAL: cpu average usage: 1.00 % (5m) | 'cpu.utilization.5s.percentage'=1.00%;;;0;100 'cpu.utilization.1m.percentage'=1.00%;;;0;100 'cpu.utilization.15m.percentage'=1.00%;;0:0.5;0;100

@{teldat_cpu_tests}
...                             &{teldat_cpu_test1}
...                             &{teldat_cpu_test2}
...                             &{teldat_cpu_test3}
...                             &{teldat_cpu_test4}
...                             &{teldat_cpu_test5}
...                             &{teldat_cpu_test6}
...                             &{teldat_cpu_test7}

# Test simple usage of the memory mode
&{teldat_memory_test1}
...                             warningusage=
...                             criticalusage=
...                             warningusagefree=
...                             criticalusagefree=
...                             warningusageprct=
...                             criticalusageprct=
...                             result=OK: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100

# Test memory mode with warning-usage option set to a 100
&{teldat_memory_test2}
...                             warningusage=100
...                             criticalusage=
...                             warningusagefree=
...                             criticalusagefree=
...                             warningusageprct=
...                             criticalusageprct=
...                             result=WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;0:100;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100

# Test memory mode with critical-usage option set to a 100
&{teldat_memory_test3}
...                             warningusage=
...                             criticalusage=100
...                             warningusagefree=
...                             criticalusagefree=
...                             warningusageprct=
...                             criticalusageprct=
...                             result=CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;0:100;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100

# Test memory mode with warning-usage-free option set to a 100
&{teldat_memory_test4}
...                             warningusage=
...                             criticalusage=
...                             warningusagefree=100
...                             criticalusagefree=
...                             warningusageprct=
...                             criticalusageprct=
...                             result=WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;0:100;;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100

# Test memory mode with critical-usage-free option set to a 100
&{teldat_memory_test5}
...                             warningusage=
...                             criticalusage=
...                             warningusagefree=
...                             criticalusagefree=100
...                             warningusageprct=
...                             criticalusageprct=
...                             result=CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;0:100;0;268435456 'system#memory.usage.percentage'=39.27%;;;0;100

# Test memory mode with warning-usage-prct option set to a 30
&{teldat_memory_test6}
...                             warningusage=
...                             criticalusage=
...                             warningusagefree=
...                             criticalusagefree=
...                             warningusageprct=30
...                             criticalusageprct=
...                             result=WARNING: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;0:30;;0;100

# Test memory mode with critical-usage-prct option set to a 30
&{teldat_memory_test7}
...                             warningusage=
...                             criticalusage=
...                             warningusagefree=
...                             criticalusagefree=
...                             warningusageprct=
...                             criticalusageprct=30
...                             result=CRITICAL: Memory 'system' total: 256.00 MB used: 100.54 MB (39.27%) free: 155.46 MB (60.73%) | 'system#memory.usage.bytes'=105419600B;;;0;268435456 'system#memory.free.bytes'=163015856B;;;0;268435456 'system#memory.usage.percentage'=39.27%;;0:30;0;100

@{teldat_memory_tests}
...                             &{teldat_memory_test1}
...                             &{teldat_memory_test2}
...                             &{teldat_memory_test3}
...                             &{teldat_memory_test4}
...                             &{teldat_memory_test5}
...                             &{teldat_memory_test6}
...                             &{teldat_memory_test7}


*** Test Cases ***

Network Teldat SNMP CPU
    [Documentation]    Network Teldat SNMP CPU
    [Tags]    network    teldat    snmp
    FOR    ${teldat_cpu_test}    IN    @{teldat_cpu_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=cpu
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2c
        ...    --snmp-port=2024
        ...    --snmp-community=network/teldat/snmp/teldat
        ${length}    Get Length    ${teldat_cpu_test.warningcpuutilization5s}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-cpu-utilization-5s=${teldat_cpu_test.warningcpuutilization5s}
        END
        ${length}    Get Length    ${teldat_cpu_test.criticalcpuutilization5s}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-cpu-utilization-5s=${teldat_cpu_test.criticalcpuutilization5s}
        END
        ${length}    Get Length    ${teldat_cpu_test.warningcpuutilization1m}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-cpu-utilization-1m=${teldat_cpu_test.warningcpuutilization1m}
        END
        ${length}    Get Length    ${teldat_cpu_test.criticalcpuutilization1m}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-cpu-utilization-1m=${teldat_cpu_test.criticalcpuutilization1m}
        END
        ${length}    Get Length    ${teldat_cpu_test.warningcpuutilization5m}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-cpu-utilization-5m=${teldat_cpu_test.warningcpuutilization5m}
        END
        ${length}    Get Length    ${teldat_cpu_test.criticalcpuutilization5m}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-cpu-utilization-5m=${teldat_cpu_test.criticalcpuutilization5m}
        END
        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${teldat_cpu_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${teldat_cpu_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END

Network Teldat SNMP Memory
    [Documentation]    Network Teldat SNMP memory
    [Tags]    network    teldat    snmp
    FOR    ${teldat_memory_test}    IN    @{teldat_memory_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=memory
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2c
        ...    --snmp-port=2024
        ...    --snmp-community=network/teldat/snmp/teldat
        ${length}    Get Length    ${teldat_memory_test.warningusage}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-usage=${teldat_memory_test.warningusage}
        END
        ${length}    Get Length    ${teldat_memory_test.criticalusage}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-usage=${teldat_memory_test.criticalusage}
        END
        ${length}    Get Length    ${teldat_memory_test.warningusagefree}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-usage-free=${teldat_memory_test.warningusagefree}
        END
        ${length}    Get Length    ${teldat_memory_test.criticalusagefree}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-usage-free=${teldat_memory_test.criticalusagefree}
        END
        ${length}    Get Length    ${teldat_memory_test.warningusageprct}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --warning-usage-prct=${teldat_memory_test.warningusageprct}
        END
        ${length}    Get Length    ${teldat_memory_test.criticalusageprct}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --critical-usage-prct=${teldat_memory_test.criticalusageprct}
        END
        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${teldat_memory_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${teldat_memory_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END
