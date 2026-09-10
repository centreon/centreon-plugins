*** Settings ***
Documentation     Cloud Kubernetes REST API pod-usage

Resource          ${CURDIR}${/}..${/}..${/}resources/import.resource

Suite Setup       Start Mockoon    ${MOCKOON_JSON}
Suite Teardown    Stop Mockoon
Test Timeout      120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}cloud-kubernetes.mockoon.json
${HOSTNAME}        127.0.0.1
${APIPORT}         3000
${CMD}             ${CENTREON_PLUGINS}
...                --plugin=cloud::kubernetes::plugin
...                --mode=pod-usage
...                --hostname=${HOSTNAME}
...                --token=x-xxx
...                --proto=http
...                --port=${APIPORT}
...                --custommode=api


*** Test Cases ***
Pod Usage ${tc}
    [Tags]    cloud    kubernetes
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extraoptions
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All pods usage are ok | 'default/cache-1#pod.cpu.usage.millicores'=10;;;0; 'default/cache-1#pod.memory.usage.bytes'=16777216B;;;0; 'default/idle-1#pod.cpu.usage.millicores'=0;;;0; 'default/idle-1#pod.cpu.usage.percentage'=0.00%;;;0;100 'default/idle-1#pod.memory.usage.bytes'=0B;;;0; 'default/idle-1#pod.memory.usage.percentage'=0.00%;;;0;100 'default/multi-1#pod.cpu.usage.millicores'=25;;;0; 'default/multi-1#pod.cpu.usage.percentage'=12.50%;;;0;100 'default/multi-1#pod.memory.usage.bytes'=26214400B;;;0; 'default/multi-1#pod.memory.usage.percentage'=12.50%;;;0;100 'default/web-1#pod.cpu.usage.millicores'=50;;;0; 'default/web-1#pod.cpu.usage.percentage'=20.00%;;;0;100 'default/web-1#pod.memory.usage.bytes'=33554432B;;;0; 'default/web-1#pod.memory.usage.percentage'=50.00%;;;0;100
    ...    2
    ...    --filter-name='multi-1' --filter-container-name='app'
    ...    OK: Pod 'default/multi-1' CPU usage: 20 millicores, CPU usage: 20.00% of requests, Memory usage: 20.00 MB, Memory usage: 20.00% of requests | 'default/multi-1#pod.cpu.usage.millicores'=20;;;0; 'default/multi-1#pod.cpu.usage.percentage'=20.00%;;;0;100 'default/multi-1#pod.memory.usage.bytes'=20971520B;;;0; 'default/multi-1#pod.memory.usage.percentage'=20.00%;;;0;100
    ...    3
    ...    --filter-namespace='no-such-ns'
    ...    UNKNOWN: No pod found matching filters
    ...    4
    ...    --filter-name='web-1' --warning-pod-cpu-usage=10
    ...    WARNING: Pod 'default/web-1' CPU usage: 50 millicores | 'default/web-1#pod.cpu.usage.millicores'=50;0:10;;0; 'default/web-1#pod.cpu.usage.percentage'=20.00%;;;0;100 'default/web-1#pod.memory.usage.bytes'=33554432B;;;0; 'default/web-1#pod.memory.usage.percentage'=50.00%;;;0;100
    ...    5
    ...    --filter-name='web-1' --critical-pod-memory-percentage=40
    ...    CRITICAL: Pod 'default/web-1' Memory usage: 50.00% of requests | 'default/web-1#pod.cpu.usage.millicores'=50;;;0; 'default/web-1#pod.cpu.usage.percentage'=20.00%;;;0;100 'default/web-1#pod.memory.usage.bytes'=33554432B;;;0; 'default/web-1#pod.memory.usage.percentage'=50.00%;;0:40;0;100
    ...    6
    ...    --filter-name='idle-1' --warning-pod-cpu-percentage=1
    ...    OK: Pod 'default/idle-1' CPU usage: 0 millicores, CPU usage: 0.00% of requests, Memory usage: 0.00 B, Memory usage: 0.00% of requests | 'default/idle-1#pod.cpu.usage.millicores'=0;;;0; 'default/idle-1#pod.cpu.usage.percentage'=0.00%;0:1;;0;100 'default/idle-1#pod.memory.usage.bytes'=0B;;;0; 'default/idle-1#pod.memory.usage.percentage'=0.00%;;;0;100
    ...    7
    ...    --namespace='broken-metrics'
    ...    UNKNOWN: API return error code '404' (add --debug option for detailed message)
