*** Settings ***
Documentation       Applications Rubrik Restapi plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}applications-rubrik-restapi.json

${CMD}      ${CENTREON_PLUGINS} --plugin=apps::backup::rubrik::restapi::plugin 
...         --mode=jobs 
...         --hostname='localhost'
...         --api-username='api-username' 
...         --api-password='api-password' 
...         --port='3000' 
...         --proto='http'


*** Test Cases ***
Interfaces by id ${tc}/1
    [Tags]    applications    backup   rubrik    restapi    jobs
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:        tc    extra_options            expected_result    --
            ...      1     ${EMPTY}                 OK: job 'centreon.groupe.active volumes' [type: backup] number of failed executions: 0.00 % - last execution * - last execution started: 2024-07-18T20:00:01.382Z status: Success | 'jobs.executions.detected.count'=4;;;0; 'centreon.groupe.active volumes~backup#job.executions.failed.percentage'=0.00%;;;0;100 'centreon.groupe.active volumes~backup#job.execution.last.seconds'=-*s;;;0;
 