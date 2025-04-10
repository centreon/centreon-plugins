*** Settings ***
Documentation       Check the licenses status

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}Mockoon.json
${HOSTNAME}          host.docker.internal
${APIPORT}           3002
${cmd}              ${CENTREON_PLUGINS}
...                 --plugin=network::stormshield::api::plugin
...                 --custommode=api
...                 --hostname=${HOSTNAME}
...                 --api-username=username
...                 --api-password=password
...                 --proto=http
...                 --port=${APIPORT}
...                 --debug
...                 --timeout=10


*** Test Cases ***
vpn-tunnels ${tc}
    [Tags]    network    restapi
    ${command}    Catenate
    ...    ${cmd}
    ...    --mode=vpn-tunnels
    ...    ${extraoptions}

    Log    ${cmd}
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:         tc    extraoptions                                            expected_result    --
            ...       1     --verbose                                                OK: status : skipped (no value(s))
