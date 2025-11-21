*** Settings ***
Documentation       Check Commvault REST API Check

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}commvault.mockoon.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=apps::backup::commvault::commserve::restapi::plugin
...                 --hostname=${HOSTNAME}
...                 --api-username='username'
...                 --api-password='password'
...                 --proto='http'
...                 --mode=jobs
...                 --port=${APIPORT}


*** Test Cases ***
jobs ${tc}
    [Tags]    apps    backup    commvalt    commserve    restapi

    ${command}    Catenate
    ...    ${CMD}

    ${command}    Catenate    ${CMD} --http-backend=curl ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                expected_result    --
            ...      1     ${EMPTY}                                     OK: Total jobs: 6 - All policies are ok | 'jobs.total.count'=6;;;0; 'jobs.problems.current.count'=0;;;0;
            ...      2     --filter-client-name='Xg'                    OK: Total jobs: 1 - Policy 'XXXX-Plan' 0 problem(s) detected | 'jobs.total.count'=1;;;0; 'jobs.problems.current.count'=0;;;0;
            ...      3     --filter-policy-id=2                         OK: Total jobs: 2 - Policy 'XXXX-Plan' 0 problem(s) detected | 'jobs.total.count'=2;;;0; 'jobs.problems.current.count'=0;;;0;
            ...      4     --filter-type='Incr Backup'                  OK: Total jobs: 1 - Policy 'XXXX-Plan' 0 problem(s) detected | 'jobs.total.count'=1;;;0; 'jobs.problems.current.count'=0;;;0;
            ...      5     --filter-policy-name='XXXX-Plan'             OK: Total jobs: 5 - Policy 'XXXX-Plan' 0 problem(s) detected | 'jobs.total.count'=5;;;0; 'jobs.problems.current.count'=0;;;0;
            ...      6     --filter-client-group="eta YYYY"             OK: Total jobs: 5 - All policies are ok | 'jobs.total.count'=5;;;0; 'jobs.problems.current.count'=0;;;0;
            ...      7     --critical-jobs-total=10:                    CRITICAL: Total jobs: 6 | 'jobs.total.count'=6;;10:;0; 'jobs.problems.current.count'=0;;;0;
            ...      8     --warning-status='\\%\{status\} !~ /none/'   WARNING: 6 problem(s) detected | 'jobs.total.count'=6;;;0; 'jobs.problems.current.count'=6;;;0;
            ...      9     --warning-long='\\%\{elapsed\} >10'          WARNING: 1 problem(s) detected | 'jobs.total.count'=6;;;0; 'jobs.problems.current.count'=1;;;0;
