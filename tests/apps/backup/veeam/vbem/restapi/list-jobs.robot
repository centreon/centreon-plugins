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
    [Tags]    apps    backup   veeam    vbem    restapi    list-jobs
    
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}
    
    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:    tc     extraoptions                      expected_result   --
        ...      1      --timeframe=''                    List jobs: [uid: urn:veeam:Job][jobName: Backup client 2 - Tous les jours][jobType: Backup] [uid: urn:veeam:Job:xxxxxxxx-yyyy-zzzz-1111-aaaaaaaaaaaa][jobName: PROD Job 1][jobType: Backup]