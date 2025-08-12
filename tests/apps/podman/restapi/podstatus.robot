*** Settings ***
Documentation       Test the Podman pod-status mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}podman.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::podman::restapi::plugin
...                 --custommode=api
...                 --mode=pod-status
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
Pod status ${tc}
    [Documentation]    Check the pod status
    [Tags]    apps    podman    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --pod-name=blog
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                         expected_result    --
            ...       1     ${EMPTY}                             OK: CPU: 1.46%, Memory: 459.41MB, Running containers: 5, Stopped containers: 2, Paused containers: 1, State: Running | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       2     --warning-cpu-usage=1                WARNING: CPU: 1.46% | 'podman.pod.cpu.usage.percent'=1.46%;0:1;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       3     --critical-cpu-usage=1               CRITICAL: CPU: 1.46% | 'podman.pod.cpu.usage.percent'=1.46%;;0:1;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       4     --warning-memory-usage=250000000     WARNING: Memory: 459.41MB | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;0:250000000;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       5     --critical-memory-usage=400000000    CRITICAL: Memory: 459.41MB | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;0:400000000;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       6     --warning-running-containers=3       WARNING: Running containers: 5 | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;0:3;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       7     --critical-running-containers=3      CRITICAL: Running containers: 5 | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;0:3;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       8     --warning-stopped-containers=0       WARNING: Stopped containers: 2 | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;0:0;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       9     --critical-stopped-containers=1      CRITICAL: Stopped containers: 2 | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;0:1;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       10    --warning-paused-containers=0        WARNING: Paused containers: 1 | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;0:0;;0;
            ...       11    --critical-paused-containers=0       CRITICAL: Paused containers: 1 | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;0:0;0;

Pod status ${tc}
    [Documentation]    Check the pod status
    [Tags]    apps    podman    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --pod-name=degreded
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                                                                              expected_result    --
            ...       12    --warning-state='\\\%{state} =~ /Degraded/' --critical-state='\\\%{state} =~ /Exited/'    WARNING: State: Degraded | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
            ...       13    --warning-state='\\\%{state} =~ /Exited/' --critical-state='\\\%{state} =~ /Degraded/'    CRITICAL: State: Degraded | 'podman.pod.cpu.usage.percent'=1.46%;;;0;100 'podman.pod.memory.usage.bytes'=481727346.688B;;;0; 'podman.pod.containers.running.count'=5;;;0; 'podman.pod.containers.stopped.count'=2;;;0; 'podman.pod.containers.paused.count'=1;;;0;
