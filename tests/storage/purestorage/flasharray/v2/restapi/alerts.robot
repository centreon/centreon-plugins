*** Settings ***
Documentation       Check alerts.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mokoon.json
#${HOSTNAME}          host.docker.internal
#${APIPORT}           3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::purestorage::flasharray::v2::restapi::plugin
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
    ...    --mode=alerts
    ...    ${extra_options}
    Ctn Verify Command Output    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                                                                                                                     expected_result    --
            ...       1       --filter-category='array'                                                                                                                                         CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0;
            ...       2       --warning-status='\\\%{component_name} eq "ct1.eth0"' --filter-category="toto" --insecure --verbose                                                               WARNING: 1 problem(s) detected | 'alerts.detected.count'=1;;;0; warning: alert [component: ct1.eth0] [severity: warning] [category: toto] [issue: failure]
            ...       3       --critical-status='\\\%{component_name} eq "ch0" and \\\%{severity} =~ /critical/i' --filter-category="array" --insecure --verbose                                CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0; critical: alert [component: ch0] [severity: critical] [category: array] [issue: shelf drive failures(s)]
            ...       4       --memory=""                                                                                                                                                       CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0;