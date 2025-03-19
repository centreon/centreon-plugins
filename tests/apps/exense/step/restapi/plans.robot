*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}plans.json
${HOSTNAME}         host.docker.internal
${APIPORT}          3000

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::exense::step::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=15
...                 --token=token   


*** Test Cases ***
plans ${tc}
    [Tags]    apps    
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=plans
    ...    ${extraoptions}
    #Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extraoptions                                                                               expected_result    --
            ...       1   ${EMPTY}                                                                                   OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       2   --tenant-name='[All]'                                                                      OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       3   --critical-plan-execution-status='\\\%{planName} eq NORUN'                                 OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       4   --unknown-plan-execution-status='\\\%{planName} eq plop2-test'                             OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       5   --warning-plan-execution-status='\\\%{planName} eq test-plan_Copy'                         OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       6   --status-failed='\\\%{result} =~ /technical_error|failed|interrupted/i'                    OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       7   --only-last-execution                                                                      OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       8   --since-timeperiod                                                                         OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       9   --filter-plan-name='test-plan'                                                             OK: All plans are ok | 'plans.detected.count'=2;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100