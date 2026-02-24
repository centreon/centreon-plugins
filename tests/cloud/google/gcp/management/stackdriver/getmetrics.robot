*** Settings ***
Documentation       GCP Management StackDriver plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}getmetrics.json

${BASE_URL}             http://${HOSTNAME}:${APIPORT}
${LOGIN_ENDPOINT}       ${BASE_URL}/oauth2/v4/token
${KEY_FILE}             ${CURDIR}${/}..${/}..${/}gcp_config.json
${CMD}                  ${CENTREON_PLUGINS} --plugin=cloud::google::gcp::management::stackdriver::plugin --mode=get-metrics 
...                     --key-file=${KEY_FILE}
...                     --scope-endpoint=${BASE_URL}
...                     --authorization-endpoint=${LOGIN_ENDPOINT}
...                     --monitoring-endpoint=${BASE_URL}


*** Test Cases ***
GetMetric ${tc}
    [Tags]    google    gcp    cloud    metrics    mockoon
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=get-metrics
    ...    --dimension-name='resource.labels.project_id'
    ...    --dimension-operator='equals'
    ...    --dimension-value='service-name-masque'
    ...    --api=''
    ...    --metric='pending_queue/pending_requests'
    ...    --timeframe='900' 
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extra_options                                  expected_result    --
            ...       1   ${EMPTY}                                       OK: Metric 'loadbalancing.googleapis.comhttps/frontend_tcp_rtt' of resource 'example-project' value is 22 | 'average#loadbalancing.googleapis.comhttps.frontend_tcp_rtt'=22s;;;;
            ...       2   --distribution-value=count                     OK: Metric 'loadbalancing.googleapis.comhttps/frontend_tcp_rtt' of resource 'example-project' value is 54 | 'average#loadbalancing.googleapis.comhttps.frontend_tcp_rtt'=54s;;;;
            ...       3   --aggregation='total'                          OK: Metric 'loadbalancing.googleapis.comhttps/frontend_tcp_rtt' of resource 'example-project' value is 44 | 'total#loadbalancing.googleapis.comhttps.frontend_tcp_rtt'=44s;;;;   
            ...       4   --aggregation='minimum'                        OK: Metric 'loadbalancing.googleapis.comhttps/frontend_tcp_rtt' of resource 'example-project' value is 16 | 'minimum#loadbalancing.googleapis.comhttps.frontend_tcp_rtt'=16s;;;;
            ...       5   --aggregation='maximum'                        OK: Metric 'loadbalancing.googleapis.comhttps/frontend_tcp_rtt' of resource 'example-project' value is 28 | 'maximum#loadbalancing.googleapis.comhttps.frontend_tcp_rtt'=28s;;;;
            ...       6   --warning-metric='10'                          WARNING: Metric 'loadbalancing.googleapis.comhttps/frontend_tcp_rtt' of resource 'example-project' value is 22 | 'average#loadbalancing.googleapis.comhttps.frontend_tcp_rtt'=22s;0:10;;;
            ...       7   --critical-metric='10'                         CRITICAL: Metric 'loadbalancing.googleapis.comhttps/frontend_tcp_rtt' of resource 'example-project' value is 22 | 'average#loadbalancing.googleapis.comhttps.frontend_tcp_rtt'=22s;;0:10;;
