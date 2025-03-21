*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}plans.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::exense::step::restapi::plugin
...                 --mode=plans
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --timeout=10
...                 --token=token   


*** Test Cases ***
plans ${tc}
    [Tags]    apps    
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extraoptions                                                                                                     expected_result    --
            ...       1   ${EMPTY}                                                                                                         OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       2   --tenant-name='[All]' --filter-plan-name='test-plan'                                                             OK: All plans are ok | 'plans.detected.count'=2;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       3   --critical-plan-execution-status='\\\%{planName} eq NORUN' --filter-plan-name='test-plan'                        OK: All plans are ok | 'plans.detected.count'=2;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       4   --unknown-plan-execution-status='\\\%{planName} eq plop2-test' --filter-plan-name='test-plan'                    OK: All plans are ok | 'plans.detected.count'=2;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       5   --warning-plan-execution-status='\\\%{planName} eq test-plan_Copy' --filter-plan-name='test-plan'                OK: All plans are ok | 'plans.detected.count'=2;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       6   --status-failed='\\\%{result} =~ /technical_error|failed|interrupted/i'                                          OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       7   --only-last-execution                                                                                            OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       8   --since-timeperiod                                                                                               OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       9   --warning-plans-detected=1                                                                                       WARNING: Number of plans detected: 3 | 'plans.detected.count'=3;0:1;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       10  --critical-plans-detected=2                                                                                      CRITICAL: Number of plans detected: 3 | 'plans.detected.count'=3;;0:2;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       11  --warning-plan-executions-detected=1:1 --filter-plan-name='plop2-test'                                           WARNING: plan 'plop2-test' number of plan executions detected: 0 | 'plans.detected.count'=1;;;0; 'plop2-test#plan.executions.detected.count'=0;1:1;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       12  --critical-plan-executions-detected=2:2 --filter-plan-name='plop2-test'                                          CRITICAL: plan 'plop2-test' number of plan executions detected: 0 | 'plans.detected.count'=1;;;0; 'plop2-test#plan.executions.detected.count'=0;;2:2;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       13  --warning-plan-executions-failed-prct=1:1 --filter-plan-name='plop2-test'                                        WARNING: plan 'plop2-test' number of failed executions: 0.00 % | 'plans.detected.count'=1;;;0; 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;1:1;;0;100
            ...       14  --critical-plan-executions-failed-prct=2:2 --filter-plan-name='test-plan'                                        CRITICAL: plan 'test-plan' number of failed executions: 0.00 % - plan 'test-plan_Copy' number of failed executions: 0.00 % | 'plans.detected.count'=2;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;2:2;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;2:2;0;100
            ...       15  --warning-plan-execution-last=1:1                                                                                OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       16  --critical-plan-execution-last=2:2                                                                               OK: All plans are ok | 'plans.detected.count'=3;;;0; 'test-plan#plan.executions.detected.count'=0;;;0; 'test-plan#plan.executions.failed.percentage'=0.00%;;;0;100 'test-plan_Copy#plan.executions.detected.count'=0;;;0; 'test-plan_Copy#plan.executions.failed.percentage'=0.00%;;;0;100 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       17  --warning-plan-running-duration=1 --filter-plan-name='plop2-test'                                                OK: plan 'plop2-test' number of plan executions detected: 0 - number of failed executions: 0.00 % | 'plans.detected.count'=1;;;0; 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100
            ...       18  --critical-plan-running-duration=2 --filter-plan-name='plop2-test'                                               OK: plan 'plop2-test' number of plan executions detected: 0 - number of failed executions: 0.00 % | 'plans.detected.count'=1;;;0; 'plop2-test#plan.executions.detected.count'=0;;;0; 'plop2-test#plan.executions.failed.percentage'=0.00%;;;0;100