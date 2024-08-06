*** Settings ***
Documentation       Applications Rubrik Restapi jobs

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}         ${CURDIR}${/}applications-rubrik-restapi.json

${CMD}      ${CENTREON_PLUGINS} --plugin=apps::backup::rubrik::restapi::plugin 
...         --mode=cache 
...         --hostname='localhost'
...         --api-username='api-username' 
...         --api-password='api-password' 
...         --port='3000' 
...         --proto='http'


*** Test Cases ***
Cache ${tc}/1
    [Tags]    applications    backup   rubrik    restapi    cache
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
            ...      1     ${EMPTY}                 OK: Cache files created successfully
 