*** Settings ***
Documentation       Applications Rubrik Restapi jobs

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}applications-rubrik-restapi.json
${HOSTNAME}        127.0.0.1
${APIPORT}         3000
${CMD}             ${CENTREON_PLUGINS} --plugin=apps::backup::rubrik::restapi::plugin 
...                --mode=jobs 
...                --hostname=${HOSTNAME}
...                --api-username='api-username' 
...                --api-password='api-password' 
...                --port=${APIPORT}  
...                --proto='http'

*** Test Cases ***
Jobs ${tc}/11
    [Tags]    applications    backup   rubrik    restapi    jobs
    ${output}    Run    ${CMD} ${extraoptions}

    ${output}    Strip String    ${output}

    Should Match Regexp
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nObtained:\n${output}\n

    Examples:    tc    extraoptions            expected_result   --
        ...      1     ${EMPTY}                                                                          OK: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % - last execution .* - last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=4;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=-*s;;;0;
        ...      2      --unknown-execution-status='\\%\{status\} eq "Success"'                              UNKNOWN: job 'centreon.groupe.active volumes' \[type: backup\] last execution started: 2024-07-18T20:00:01.382Z status: Success
        ...      3      --warning-execution-status='\\%\{status\} eq "Success"'                              WARNING: job 'centreon.groupe.active volumes' \[type: backup\] last execution started: 2024-07-18T20:00:01.382Z status: Success
        ...      4      --critical-execution-status='\\%\{status\} eq "Success"'                             CRITICAL: job 'centreon.groupe.active volumes' \[type: backup\] last execution started: 2024-07-18T20:00:01.382Z status: Success
        ...      5      --warning-jobs-executions-detected=2 --critical-jobs-executions-detected=4       WARNING: Number of jobs executions detected: 4 \| 'jobs.executions.detected.count'=4;0:2;0:5;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=1623265s;;;0;
        ...      6      --warning-jobs-executions-detected=2 --critical-jobs-executions-detected=3       CRITICAL: Number of jobs executions detected: 4 \| 'jobs.executions.detected.count'=4;0:2;0:3;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=1623293s;;;0;
        ...      7      --warning-job-executions-failed-prct=1:1 --critical-job-executions-failed-prct=1 WARNING: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % \| 'jobs.executions.detected.count'=4;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;1:1;0:1;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=1623034s;;;0;
        ...      8      --warning-job-executions-failed-prct=1 --critical-job-executions-failed-prct=1:1 CRITICAL: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % \| 'jobs.executions.detected.count'=4;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;1:1;1:1;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=1623061s;;;0;
        ...      9      --warning-job-execution-last=315360000 --critical -job-execution-last=315360000  OK: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % - last execution .* - last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=4;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=1623579s;0:315360000;0:315360000;0;
        ...      10     --warning-job-execution-last=1 --critical -job-execution-last=315360000          WARNING: job 'centreon.groupe.active volumes' \[type: backup\] last execution .* \| 'jobs.executions.detected.count'=4;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=1623671s;0:1;0:315360000;0;
        ...      11     --warning-job-execution-last=315360000 --critical -job-execution-last=1          CRITICAL: job 'centreon.groupe.active volumes' \[type: backup\] last execution .* \| 'jobs.executions.detected.count'=4;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=1623617s;0:315360000;0:1;0;



        
        