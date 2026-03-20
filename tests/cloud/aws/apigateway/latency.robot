*** Settings ***
Documentation       AWS ApiGateway latency mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=cloud::aws::apigateway::plugin
...         --custommode=awscli --region=eu-central-1
...         --aws-secret-key=secret --aws-access-key=key
...         --command=${CURDIR}${/}aws_bin${/}mock_latency_aws


*** Test Cases ***
AWS ApiGateway latency ${tc}
    [Tags]    cloud    aws    apigateway    latency
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=latency
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                                                                                                                              expected_result    --
        ...      1     --filter-metric=^Latency$ --api-gateway-type=HTTP --dimension-value=n7xex2efjb --warning-client-latency=2500 --critical-client-latency=4000               OK: 'n7xex2efjb' Statistic: 'Average' Client Latency: 700.00 ms | 'n7xex2efjb~average#apigateway.client.latency.milliseconds'=700.00;0:2500;0:4000;;
        ...      2     --filter-metric=IntegrationLatency --api-gateway-type=HTTP --dimension-value=n7xex2efjb --warning-backend-latency=2500 --critical-backend-latency=4000    OK: 'n7xex2efjb' Statistic: 'Average' Integration Latency: 500.00 ms | 'n7xex2efjb~average#apigateway.backend.latency.milliseconds'=500.00;0:2500;0:4000;;
        ...      3     --filter-metric=^Latency$ --api-gateway-type=HTTP --dimension-value=n7xex2efjb --warning-client-latency=500 --critical-client-latency=800                 WARNING: 'n7xex2efjb' Statistic: 'Average' Client Latency: 700.00 ms | 'n7xex2efjb~average#apigateway.client.latency.milliseconds'=700.00;0:500;0:800;;
        ...      4     --filter-metric=^Latency$ --api-gateway-type=HTTP --dimension-value=n7xex2efjb --critical-client-latency=500                                              CRITICAL: 'n7xex2efjb' Statistic: 'Average' Client Latency: 700.00 ms | 'n7xex2efjb~average#apigateway.client.latency.milliseconds'=700.00;;0:500;;
        ...      5     --filter-metric=^Latency$ --api-gateway-type=REST --api-name=my-api --warning-client-latency=2500 --critical-client-latency=4000                          OK: 'my-api' Statistic: 'Average' Client Latency: 700.00 ms | 'my-api~average#apigateway.client.latency.milliseconds'=700.00;0:2500;0:4000;;
        ...      6     --api-gateway-type=INVALID --dimension-value=n7xex2efjb                                                                                                   UNKNOWN: Unsupported --api-gateway-type option.
        ...      7     --api-gateway-type=HTTP --dimension-value=                                                                                                                UNKNOWN: No metrics. Check your options or use --zeroed option to set 0 on undefined values

