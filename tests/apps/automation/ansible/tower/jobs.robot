*** Settings ***
Documentation       Check the jobs mode with api custom mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}ansible_tower.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::automation::ansible::tower::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --username=username
...                 --password=password
...                 --port=${APIPORT}


*** Test Cases ***
jobs ${tc}
    [Documentation]    Check the number of returned jobs
    [Tags]    apps    automation    ansible    jobs
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=jobs
    ...    ${extraoptions}
    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc  extraoptions                                 expected_result    --
            ...       1   --filter-name=''                             OK: Jobs total: 2, successful: 0, failed: 0, running: 0 | 'jobs.total.count'=2;;;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2
            ...       2   --filter-name=toto                           OK: Jobs total: 0, successful: 0, failed: 0, running: 0 | 'jobs.total.count'=0;;;0; 'jobs.successful.count'=0;;;0;0 'jobs.failed.count'=0;;;0;0 'jobs.running.count'=0;;;0;0 'jobs.canceled.count'=0;;;0;0 'jobs.pending.count'=0;;;0;0 'jobs.default.count'=0;;;0;0
            ...       3   --filter-name=toto --critical-total=1:1      CRITICAL: Jobs total: 0 | 'jobs.total.count'=0;;1:1;0; 'jobs.successful.count'=0;;;0;0 'jobs.failed.count'=0;;;0;0 'jobs.running.count'=0;;;0;0 'jobs.canceled.count'=0;;;0;0 'jobs.pending.count'=0;;;0;0 'jobs.default.count'=0;;;0;0
            ...       4   --filter-name='' --critical-total=1:1        CRITICAL: Jobs total: 2 | 'jobs.total.count'=2;;1:1;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2
            ...       5   --filter-name='' --critical-total=2:2        OK: Jobs total: 2, successful: 0, failed: 0, running: 0 | 'jobs.total.count'=2;;2:2;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2
            ...       6   --critical-total=2:1                         CRITICAL: Jobs total: 2 | 'jobs.total.count'=2;;2:1;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2
            ...       7   --filter-name='' --display-failed-jobs       OK: Jobs total: 2, successful: 0, failed: 0, running: 0 | 'jobs.total.count'=2;;;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2         
            ...       8   --filter-name='' --warning-total=1:1         WARNING: Jobs total: 2 | 'jobs.total.count'=2;1:1;;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2
            ...       9   --filter-name='' --warning-total=2:2         OK: Jobs total: 2, successful: 0, failed: 0, running: 0 | 'jobs.total.count'=2;2:2;;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2
            ...       10  --filter-name=toto --warning-total=1:1       WARNING: Jobs total: 0 | 'jobs.total.count'=0;1:1;;0; 'jobs.successful.count'=0;;;0;0 'jobs.failed.count'=0;;;0;0 'jobs.running.count'=0;;;0;0 'jobs.canceled.count'=0;;;0;0 'jobs.pending.count'=0;;;0;0 'jobs.default.count'=0;;;0;0
            ...       11  --warning-total=1:2                          OK: Jobs total: 2, successful: 0, failed: 0, running: 0 | 'jobs.total.count'=2;1:2;;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2   
            ...       12  --warning-total=2:1                          WARNING: Jobs total: 2 | 'jobs.total.count'=2;2:1;;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2   
            ...       13  --critical-total=1:2                         OK: Jobs total: 2, successful: 0, failed: 0, running: 0 | 'jobs.total.count'=2;;1:2;0; 'jobs.successful.count'=0;;;0;2 'jobs.failed.count'=0;;;0;2 'jobs.running.count'=0;;;0;2 'jobs.canceled.count'=0;;;0;2 'jobs.pending.count'=0;;;0;2 'jobs.default.count'=0;;;0;2
