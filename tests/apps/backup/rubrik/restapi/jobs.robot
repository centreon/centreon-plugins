*** Settings ***
Documentation       Check Rubrik REST API jobs

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}applications-rubrik-restapi.json
${cmd}              ${CENTREON_PLUGINS} 
...                 --plugin=apps::backup::rubrik::restapi::plugin 
...                 --hostname=${HOSTNAME}
...                 --api-username='username' 
...                 --api-password='password' 
...                 --proto='http'
...                 --port=${APIPORT}

*** Test Cases ***
jobs ${tc}/11
    [Tags]    apps    backup   rubrik    restapi    jobs
    
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=jobs
    ...    ${extraoptions}
    
    Log    ${command}
    
    ${output}    Run    ${command}
    
    Should Match Regexp    ${output}    ${expected_result}

    Examples:    tc     extraoptions            expected_result   --
        ...      1      ${EMPTY}                                                                             OK: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % - last execution .* - last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*s;;;0;
        ...      2      --unknown-execution-status='\\%\{status\} eq "Success"'                              UNKNOWN: job 'centreon.groupe.active volumes' \[type: backup\] last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*s;;;0;
        ...      3      --warning-execution-status='\\%\{status\} eq "Success"'                              WARNING: job 'centreon.groupe.active volumes' \[type: backup\] last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*s;;;0;
        ...      4      --critical-execution-status='\\%\{status\} eq "Success"'                             CRITICAL: job 'centreon.groupe.active volumes' \[type: backup\] last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*s;;;0;
        ...      5      --warning-jobs-executions-detected=1 --critical-jobs-executions-detected=3           WARNING: Number of jobs executions detected: 2 \| 'jobs.executions.detected.count'=2;0:2;0:5;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*;;;0;
        ...      6      --warning-jobs-executions-detected=1 --critical-jobs-executions-detected=1           CRITICAL: Number of jobs executions detected: 2 \| 'jobs.executions.detected.count'=2;0:2;0:3;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*;;;0;
        ...      7      --warning-job-executions-failed-prct=1:1 --critical-job-executions-failed-prct=1     WARNING: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;1:1;0:1;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*;;;0;
        ...      8      --warning-job-executions-failed-prct=1 --critical-job-executions-failed-prct=1:1     CRITICAL: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;0:1;1:1;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*;;;0;
        ...      9      --warning-job-execution-last=315360000 --critical-job-execution-last=315360000       OK: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % - last execution .* - last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*;0:315360000;0:315360000;0;
        ...      10     --warning-job-execution-last=1 --critical-job-execution-last=315360000               WARNING: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % - last execution .* - last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*;0:1;0:315360000;0;
        ...      11     --warning-job-execution-last=315360000 --critical-job-execution-last=315360000       CRITICAL: job 'centreon.groupe.active volumes' \[type: backup\] number of failed executions: 0.00 % - last execution .* - last execution started: 2024-07-18T20:00:01.382Z status: Success \| 'jobs.executions.detected.count'=2;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=.*;0:315360000;0:315360000;0;