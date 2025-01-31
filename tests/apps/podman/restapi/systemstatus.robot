*** Settings ***
Documentation       Check the Podman system status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}podman.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::podman::restapi::plugin
...                 --custommode=api
...                 --mode=system-status
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
System status ${tc}
    [Documentation]    Check the system status
    [Tags]    apps    podman    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                          expected_result    --
            ...       1     ${EMPTY}                              OK: 1.19 %, 1980252160, 72836626, running containers: 3, stopped containers: 2, uptime: 52440 s | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       2     --warning-cpu-usage=0.5               WARNING: 1.19 % | 'podman.system.cpu.usage.percent'=1.19%;0:0.5;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       3     --critical-cpu-usage=1                CRITICAL: 1.19 % | 'podman.system.cpu.usage.percent'=1.19%;;0:1;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       4     --warning-memory-usage=1000000000     WARNING: 1980252160 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;0:1000000000;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       5     --critical-memory-usage=1500000000    CRITICAL: 1980252160 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;0:1500000000;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       6     --warning-swap-usage=25000000         WARNING: 72836626 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;0:25000000;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       7     --critical-swap-usage=50000000        CRITICAL: 72836626 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;0:50000000;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       8     --warning-containers-running=@2:4     WARNING: running containers: 3 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;@2:4;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       9     --critical-containers-running=@0:4    CRITICAL: running containers: 3 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;@0:4;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       10    --warning-containers-stopped=@1:2     WARNING: stopped containers: 2 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;@1:2;;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       11    --critical-containers-stopped=@2:6    CRITICAL: stopped containers: 2 | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;@2:6;0;6 'podman.system.uptime.seconds'=52440s;;;0;
            ...       12    --warning-uptime=@:60000              WARNING: uptime: 52440 s | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;@0:60000;;0;
            ...       13    --critical-uptime=@:120000            CRITICAL: uptime: 52440 s | 'podman.system.cpu.usage.percent'=1.19%;;;0;100 'podman.system.memory.usage.bytes'=1980252160B;;;0; 'podman.system.swap.usage.bytes'=72836626B;;;0; 'podman.system.containers.running.count'=3;;;0;6 'podman.system.containers.stopped.count'=2;;;0;6 'podman.system.uptime.seconds'=52440s;;@0:120000;0;
