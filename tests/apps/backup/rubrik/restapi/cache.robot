*** Settings ***
Documentation       Check Rubrik REST API jobs cache file creation

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
cache ${tc}/1
    [Tags]    apps    backup   rubrik    restapi    cache
    
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=cache

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options            expected_result    --
            ...      1     ${EMPTY}                 OK: Cache files created successfully
 