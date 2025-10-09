*** Settings ***
Documentation       Azure ServiceBus plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}azure-servicebus.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${LOGIN_ENDPOINT}       ${BASE_URL}/login
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::azure::integration::servicebus::plugin --custommode=api --subscription=subscription --tenant=tenant --client-id=client_id --client-secret=secret --resource-group=resource-group --resource='namespace' --login-endpoint=${LOGIN_ENDPOINT}


*** Test Cases ***
Namespace ${tc}
    [Tags]    cloud    azure    api    mockoon
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=namespaces
    ...    --management-endpoint=${BASE_URL}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                            expected_result    --
            ...       1   ${EMPTY}                                 OK: Instance 'namespace' Statistic 'maximum' Metrics Incoming Bytes: 645.08KB, CPU: 75.00%, Memory Usage: 75.00%, Outgoing Bytes: 645.08KB | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       2   --skip-premium-metrics                   OK: Instance 'namespace' Statistic 'maximum' Metrics Incoming Bytes: 645.08KB, Outgoing Bytes: 645.08KB | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       3   --warning-cpu-usage-percentage=70        WARNING: Instance 'namespace' Statistic 'maximum' Metrics CPU: 75.00% | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;0:70;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       4   --critical-cpu-usage-percentage=70       CRITICAL: Instance 'namespace' Statistic 'maximum' Metrics CPU: 75.00% | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;0:70;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       5   --warning-memory-usage-percentage=70     WARNING: Instance 'namespace' Statistic 'maximum' Metrics Memory Usage: 75.00% | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;0:70;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       6   --critical-memory-usage-percentage=70    CRITICAL: Instance 'namespace' Statistic 'maximum' Metrics Memory Usage: 75.00% | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;0:70;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       7   --warning-incoming-bytes=70              WARNING: Instance 'namespace' Statistic 'maximum' Metrics Incoming Bytes: 645.08KB | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;0:70;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       8   --critical-incoming-bytes=70             CRITICAL: Instance 'namespace' Statistic 'maximum' Metrics Incoming Bytes: 645.08KB | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;0:70;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;;0;
            ...       9   --warning-outgoing-bytes=70              WARNING: Instance 'namespace' Statistic 'maximum' Metrics Outgoing Bytes: 645.08KB | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;0:70;;0;
            ...       10  --critical-outgoing-bytes=70             CRITICAL: Instance 'namespace' Statistic 'maximum' Metrics Outgoing Bytes: 645.08KB | 'namespace~maximum#servicebus.namespace.incoming.bytes'=660558.00B;;;0; 'namespace~maximum#servicebus.namespace.cpu.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.memory.usage.percentage'=75.00%;;;0;100 'namespace~maximum#servicebus.namespace.outgoing.bytes'=660558.00B;;0:70;0;
                                                     