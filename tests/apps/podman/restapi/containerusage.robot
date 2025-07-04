*** Settings ***
Documentation       Test the Podman container-usage mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}podman.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::podman::restapi::plugin
...                 --custommode=api
...                 --mode=container-usage
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http


*** Test Cases ***
Container usage ${tc}
    [Documentation]    Check the container usage
    [Tags]    apps    podman    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    --container-name=${container}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    container     extraoptions                                   expected_result    --
            ...       1     wordpress     ${EMPTY}                                       OK: CPU: 0.11%, Memory: 10.85MB, Read : 435.65MB, Write : 941.43MB, Network in: 1006.00B, Network out: 2.10KB, State: running | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       2     wordpress     --warning-cpu-usage=0.1                        WARNING: CPU: 0.11% | 'podman.container.cpu.usage.percent'=0.11%;0:0.1;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       3     wordpress     --critical-cpu-usage=0.1                       CRITICAL: CPU: 0.11% | 'podman.container.cpu.usage.percent'=0.11%;;0:0.1;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       4     wordpress     --warning-memory-usage=10000000                WARNING: Memory: 10.85MB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;0:10000000;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       5     wordpress     --critical-memory-usage=10000000               CRITICAL: Memory: 10.85MB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;0:10000000;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       6     wordpress     --warning-read-io=200000000                    WARNING: Read : 435.65MB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;0:200000000;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       7     wordpress     --critical-read-io=400000000                   CRITICAL: Read : 435.65MB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;0:400000000;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       8     wordpress     --warning-write-io=500000000                   WARNING: Write : 941.43MB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;0:500000000;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       9     wordpress     --critical-write-io=750000000                  CRITICAL: Write : 941.43MB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;0:750000000;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       10    wordpress     --warning-network-in=500                       WARNING: Network in: 1006.00B | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;0:500;;0; 'podman.container.network.out'=2146B;;;0;
            ...       11    wordpress     --critical-network-in=1000                     CRITICAL: Network in: 1006.00B | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;0:1000;0; 'podman.container.network.out'=2146B;;;0;
            ...       12    wordpress     --warning-network-out=1000                     WARNING: Network out: 2.10KB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;0:1000;;0;
            ...       13    wordpress     --critical-network-out=2000                    CRITICAL: Network out: 2.10KB | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;0:2000;0;
            ...       14    wordpress     --warning-state='\\\%{state} =~ /running/'     WARNING: State: running | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       15    wordpress     --critical-state='\\\%{state} =~ /running/'    CRITICAL: State: running | 'podman.container.cpu.usage.percent'=0.11%;;;0;100 'podman.container.memory.usage.bytes'=11374592B;;;0; 'podman.container.io.read'=456812354B;;;0; 'podman.container.io.write'=987156423B;;;0; 'podman.container.network.in'=1006B;;;0; 'podman.container.network.out'=2146B;;;0;
            ...       16    toto          ${EMPTY}                                       UNKNOWN: State of container toto not found.
