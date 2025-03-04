*** Settings ***
Documentation       Check Veeam Backup Enterprise Manager using Rest API,Check jobs.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}    ${CURDIR}${/}restapi.json

${cmd}              ${CENTREON_PLUGINS} 
...                 --plugin=apps::backup::veeam::vbem::restapi::plugin 
...                 --hostname=${HOSTNAME}
...                 --api-username='username' 
...                 --api-password='password' 
...                 --proto='http'
...                 --port=${APIPORT}

*** Test Cases ***
Create cache from API
    [Tags]    apps    backup   veeam    vbem    restapi    jobs    cache
    ${output}    Run
    ...    ${CMD} --mode=cache --proto=http --port=${APIPORT} --hostname=${HOSTNAME}

    Log    ${output}
    Should Contain    ${output}    OK: Cache files created successfully

jobs ${tc}
    [Tags]    apps    backup   veeam    vbem    restapi    jobs
    
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=jobs
    ...    --cache-use
    ...    ${extraoptions}
    
    Ctn Verify Command Output    ${command}    ${expected_result}

    Examples:    tc     extraoptions                                                                                                                     expected_result   --
        ...      1      ${EMPTY}                                                                                                                         WARNING: job 'client 3 - File Backup - sto-01_VV-cli-NFS_PREPROD' [type: NasBackup] execution started: 2025-02-19T01:00:06.437Z
        ...      2      --critical-execution-status='\\\%{status} =~ /warning/i'                                                                         CRITICAL: job 'client 3 - File Backup - sto-01_VV-cli-NFS_PREPROD' [type: NasBackup] execution started: 2025-02-19T01:00:06.437Z
        ...      3      --warning-execution-status='\\\%{status} =~ /warning/i'                                                                          WARNING: job 'client 3 - File Backup - sto-01_VV-cli-NFS_PREPROD' [type: NasBackup] execution started: 2025-02-19T01:00:06.437Z status: Warning - job 'client 3 - File Backup - sto-01_VV-cli-MAIL_PROD' [type: NasBackup] execution started: 2025-02-19T04:00:05.21Z status: Warning
        ...      4      --filter-uid='urn:veeam:Job:31dc33e6-604f-4241-85f5-85d719ce1dbb'                                                                OK: job 'client 3 - File Backup - sto-01_VV-cli-MAIL_PREPROD' [type: NasBackup] number of failed executions: 0.00 %
        ...      5      --filter-name='client 6'                                                                                                         OK: All jobs are ok | 'jobs.executions.detected.count'=7;;;0; 'client 6 - Backup - Infrastructure g0t0-prod#job.executions.failed.percentage'=0.00%;;;0;100
        ...      6      --filter-type='Backup'                                                                                                           WARNING: job 'client 3 - File Backup - sto-01_VV-cli-NFS_PREPROD' [type: NasBackup] execution started: 2025-02-19T01:00:06.437Z status: Warning - job 'client 3 - File Backup - sto-01_VV-cli-MAIL_PROD' [type: NasBackup] execution started: 2025-02-19T04:00:05.21Z
        ...      7      --timeframe='86400'                                                                                                              WARNING: job 'client 3 - File Backup - sto-01_VV-cli-NFS_PREPROD' [type: NasBackup] execution started: 2025-02-19T01:00:06.437Z
        ...      8      --unknown-execution-status='\\\%{status} eq "Success"' --filter-name='client 6' --filter-type='Backup'                           UNKNOWN: job 'client 6 - Backup - Infrastructure g0t0-prod' [type: Backup] execution started: 2025-02-18T21:00:19.183Z status: Success - job 'client 6 - Backup - Infrastructure g0t0-client' [type: Backup] execution started: 2025-02-18T23:00:11.747Z status: Success
        ...      9      --warning-job-executions-failed-prct=0 --critical-job-executions-failed-prct=10                                                  CRITICAL: job 'PROD Job 1' [type: Backup] number of failed executions: 75.00 % - job 'client 3 - File Backup - sto-01_VV-cli-NFS' [type: NasBackup] number of failed executions: 50.00 % WARNING: job 'client 3 - File Backup - sto-01_VV-cli-NFS_PREPROD' [type: NasBackup] execution started: 2025-02-19T01:00:06.437Z