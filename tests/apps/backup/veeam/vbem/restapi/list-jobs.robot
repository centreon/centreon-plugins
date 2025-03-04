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
...                 --mode=list-jobs
...                 --hostname=${HOSTNAME}
...                 --api-username='username' 
...                 --api-password='password' 
...                 --proto='http'
...                 --port=${APIPORT}

*** Test Cases ***
list-jobs ${tc}
    [Tags]    apps    backup   veeam    vbem    restapi    jobs
    
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}
    
    Ctn Verify Command Output    ${command}    ${expected_result}

    Examples:    tc     extraoptions                      expected_result   --
        ...      1      --timeframe=''                    List jobs: [uid: urn:veeam:Job:04dcf89b-de95-4044-a244-d8b25b2d7d17][jobName: client 6 - Backup - Infrastructure g0t0-prod][jobType: Backup]