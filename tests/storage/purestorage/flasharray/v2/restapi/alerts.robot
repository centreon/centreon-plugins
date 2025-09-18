*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mokoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::purestorage::flasharray::v2::restapi::plugin
...                 --mode=alerts
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --api-version='2.4'
...                 --api-token='token'
...                 --port=${APIPORT}

*** Test Cases ***
alerts ${tc}
    [Tags]    storage    purestorage    flasharray    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                                                                                                                     expected_result    --
            ...       1       ${EMPTY}                                                                                                                                                          CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0;
            ...       2       --filter-category='array'                                                                                                                                         CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0;
            ...       3       --warning-status='\\\%{component_name} eq "ct1.eth0"' --filter-category="toto" --insecure --verbose                                                               WARNING: 1 problem(s) detected | 'alerts.detected.count'=1;;;0; warning: alert [component: ct1.eth0] [severity: warning] [category: toto] [issue: failure]
            ...       4       --critical-status='\\\%{component_name} eq "ch0" and \\\%{severity} =~ /critical/i' --filter-category="array" --insecure --verbose                                CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0; critical: alert [component: ch0] [severity: critical] [category: array] [issue: shelf drive failures(s)]
            ...       5       --memory                                                                                                                                                          CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0;  #first memory alert to be defined
            ...       6       --memory                                                                                                                                                          OK: 0 problem(s) detected | 'alerts.detected.count'=0;;;0;  #second check to ensure no new memory alert