*** Settings ***
Documentation       Check alerts.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s

** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}Mokoon.json

${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=storage::purestorage::flasharray::v2::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --proto='http'
...                 --api-version='2.4'
...                 --api-token='token'
...                 --port=${APIPORT}

*** Test Cases ***
alerts ${tc}
    [Documentation]    Check
    [Tags]    network    fortinet    fortigate    restapi
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=alerts
    ...    ${extra_options}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc      extra_options                                                                                                                                                          expected_result    --
            ...       1       --filter-category='array'                                                                                                                                              CRITICAL: 2 problem(s) detected | 'alerts.detected.count'=2;;;0;
            ...       2       --warning-status='\\\%{state} = "warning"'                                                                                                                             CRITICAL: 2 problem(s) detected | 'alerts.detected.count'=2;;;0;
            ...       3       --critical-status='\\\%{component_name} eq "ch0"'                                                                                                                      CRITICAL: 1 problem(s) detected | 'alerts.detected.count'=1;;;0;
            ...       4       --memory=1                                                                                                                                                             CRITICAL: 2 problem(s) detected | 'alerts.detected.count'=2;;;0;
            ...       5       --warning-status='\\\%{state} ne "closing" and \\\%{severity} =~ /warning/i and \\\%{flagged} and \\\%{code} eq "45"' --filter-category='array'                        CRITICAL: 2 problem(s) detected | 'alerts.detected.count'=2;;;0;