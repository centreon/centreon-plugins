*** Settings ***
Documentation       Test the Backbox list-devices mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}backbox.json
${HOSTNAME}             127.0.0.1
${APIPORT}              3000

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::backbox::restapi::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --api-token=token
...                 --mode=list-devices

*** Test Cases ***
List-Devices ${tc}
    [Documentation]    Check list-devices results
    [Tags]    network    backbox    restapi    list-devices
    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}
    Ctn Run Command Without Connector And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extraoptions              expected_result   --
        ...      1     ${EMPTY}                  ^Devices: (\\\\n\\\\[.*\\\\]){5}\\\\Z
        ...      2     --disco-show              \\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*\\\\/\\\\>){5}\\\\n\\\\<\\\\/data\\\\>
        ...      3     --disco-format            \\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<element\\\\>.*\\\\<\\\\/element\\\\>){9}\\\\n\\\\<\\\\/data\\\\>
