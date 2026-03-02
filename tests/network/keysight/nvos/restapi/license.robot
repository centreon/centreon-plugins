*** Settings ***
Documentation       Check the licenses status

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}keysight.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::keysight::nvos::restapi::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --api-username=username
...                 --api-password=password
...                 --proto=http
...                 --port=${APIPORT}


*** Test Cases ***
license ${tc}
    [Tags]    network    restapi
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=license
    ...    ${extraoptions}

    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                                            expected_result    --
            ...       1     --verbose                                               OK: status : skipped (no value(s))
            ...       2     --unknown-status=\\\%{status}                           OK: status : skipped (no value(s))
            ...       3     --warning-status='\\\%{status} =~ /MINOR/i'             OK: status : skipped (no value(s))
            ...       4     --critical-status='\\\%{status} =~ /MAJOR|CRITICAL/i'   OK: status : skipped (no value(s))
