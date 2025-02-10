*** Settings ***
Documentation       Test the Podman list-pods mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}podman.json

${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=apps::podman::restapi::plugin
...                 --custommode=api
...                 --mode=list-pods
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http

*** Test Cases ***
List-Pods ${tc}
    [Documentation]    Check list-pods results
    [Tags]    apps    podman    restapi

    ${command}    Catenate
    ...    ${cmd}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    extraoptions              expected_result   --
        ...      1     ${EMPTY}                  ^Pods: (\\\\n\\\\[.*\\\\]){2}\\\\Z
        ...      2     --disco-show              \\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<label .*\\\\/\\\\>){2}\\\\n\\\\<\\\\/data\\\\>
        ...      3     --disco-format            \\\\<\\\\?xml version="1.0" encoding="utf-8"\\\\?\\\\>\\\\n\\\\<data\\\\>(\\\\n\\\\s*\\\\<element\\\\>.*\\\\<\\\\/element\\\\>){3}\\\\n\\\\<\\\\/data\\\\>
