*** Settings ***
Documentation       Check Veeam Backup Enterprise Manager using Rest API,Check jobs.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}restapi.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::veeam::vbem::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --api-username='username'
...                 --api-password='password'
...                 --proto='http'
...                 --port=${APIPORT}


*** Test Cases ***
Create cache from API
    [Tags]    apps    backup    veeam    vbem    restapi    jobs    cache
    ${output}    Run
    ...    ${CMD} --mode=cache --proto=http --port=${APIPORT} --hostname=${HOSTNAME}

    Log    ${output}
    Should Contain    ${output}    OK: Cache files created successfully

jobs ${tc}
    [Tags]    apps    backup    veeam    vbem    restapi    jobs

    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=jobs
    ...    --cache-use
    ...    ${extraoptions}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:    tc     extraoptions                                                                                                                     expected_result   --
        ...      1      ${EMPTY}                                                                                                                         OK: All jobs are ok | 'jobs.executions.detected.count'=2;;;0; 'Backup client 2 - Tous les jours#job.executions.failed.percentage'=5.26%;;;0;100 'client 6 - Backup - VM Test et Lab#job.execution.last.seconds'
        ...      2      --critical-execution-status='\\\%{status} eq "Success"'                                                                          CRITICAL: job 'Backup client 2 - Tous les jours' [type: Backup] execution started: 2025-02-19T11:30:08.103Z status: Success - job 'PROD Job 1' [type: Backup] execution started: 2025-02-19T12:00:11.94Z status: Success | 'jobs.executions.detected.count'=2;;;0;
        ...      3      --warning-execution-status='\\\%{status} eq "Success"'                                                                           WARNING: job 'Backup client 2 - Tous les jours' [type: Backup] execution started: 2025-02-19T11:30:08.103Z status: Success - job 'PROD Job 1' [type: Backup] execution started: 2025-02-19T12:00:11.94Z status: Success | 'jobs.executions.detected.count'=2;;;0;
        ...      4      --filter-uid='urn:veeam:Job'                                                                                                     OK: All jobs are ok | 'jobs.executions.detected.count'=2;;;0; 'Backup client 2 - Tous les jours#job.executions.failed.percentage'=5.26%;;;0;100 'client 6 - Backup - VM Test et Lab#job.execution.last.seconds'
        ...      5      --filter-name='PROD Job 1'                                                                                                       CRITICAL: job 'PROD Job 1' [type: Backup] execution started: 2025-02-19T03:51:03.037Z status: Failed | 'jobs.executions.detected.count'=2;;;0; 'PROD Job 1#job.executions.failed.percentage'=50.00%;;;0;100
        ...      6      --filter-type='toto'                                                                                                             OK: | 'jobs.executions.detected.count'=0;;;0;
        ...      7      --timeframe='0'                                                                                                                  OK: All jobs are ok | 'jobs.executions.detected.count'=2;;;0; 'Backup client 2 - Tous les jours#job.executions.failed.percentage'=5.26%;;;0;100 'client 6 - Backup - VM Test et Lab#job.execution.last.seconds'
        ...      8      --unknown-execution-status='\\\%{status} eq "Success"' --filter-name='client 6' --filter-type='Backup'                           UNKNOWN: job 'client 6 - Backup - Infrastructure g0t0-oob' [type: Backup] execution started: 2025-02-19T11:30:08.103Z status: Success - job 'client 6 - Backup - Infrastructure g0t0-bck' [type: Backup] execution started: 2025-02-19T12:00:11.94Z status: Success | 'jobs.executions.detected.count'=2;;;0;
        ...      9      --warning-job-executions-failed-prct=0 --critical-job-executions-failed-prct=10                                                  CRITICAL: job 'PROD Job 1' [type: Backup] number of failed executions: 60.00 % WARNING: job 'Backup client 2 - Tous les jours' [type: Backup]
