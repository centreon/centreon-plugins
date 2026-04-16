*** Settings ***
Documentation       AWS ApiGateway requests mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=cloud::aws::apigateway::plugin
...         --custommode=awscli --region=eu-central-1
...         --aws-secret-key=secret --aws-access-key=key
...         --command=${CURDIR}${/}aws_bin${/}mock_requests_aws


*** Test Cases ***
AWS ApiGateway requests ${tc}
    [Tags]    cloud    aws    apigateway    requests
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=requests
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:    tc    extraoptions                                                                                                                                              expected_result    --
        ...      1     --filter-metric=Count --api-gateway-type=HTTP --dimension-value=my-api-id --warning-requests-client=200 --critical-requests-client=500                  OK: 'my-api-id' Statistic 'Sum' Metrics Client Requests: 100.00 | 'my-api-id~sum#apigateway.requests.client.count'=100.00;0:200;0:500;;
        ...      2     --filter-metric=Count --api-gateway-type=HTTP --dimension-value=my-api-id --warning-requests-client=50 --critical-requests-client=150                   WARNING: 'my-api-id' Statistic 'Sum' Metrics Client Requests: 100.00 | 'my-api-id~sum#apigateway.requests.client.count'=100.00;0:50;0:150;;
        ...      3     --filter-metric=Count --api-gateway-type=HTTP --dimension-value=my-api-id --critical-requests-client=50                                                 CRITICAL: 'my-api-id' Statistic 'Sum' Metrics Client Requests: 100.00 | 'my-api-id~sum#apigateway.requests.client.count'=100.00;;0:50;;
        ...      4     --filter-metric=4XXError --api-gateway-type=HTTP --dimension-value=my-api-id --warning-requests-errors-4xx=0 --critical-requests-errors-4xx=10          WARNING: 'my-api-id' Statistic 'Sum' Metrics HTTP 4XX Errors: 5.00 | 'my-api-id~sum#apigateway.requests.errors.4xx.count'=5.00;0:0;0:10;;
        ...      5     --filter-metric=5XXError --api-gateway-type=HTTP --dimension-value=my-api-id --critical-requests-errors-5xx=1                                           CRITICAL: 'my-api-id' Statistic 'Sum' Metrics HTTP 5XX Errors: 2.00 | 'my-api-id~sum#apigateway.requests.errors.5xx.count'=2.00;;0:1;;
        ...      6     --api-gateway-type=INVALID --dimension-value=my-api-id                                                                                                  UNKNOWN: Unsupported --api-gateway-type option.
        ...      7     --api-gateway-type=HTTP --dimension-value=                                                                                                               UNKNOWN: No metrics. Check your options or use --zeroed option to set 0 on undefined values
