*** Settings ***
Documentation       Centreon Plugins for Robot Framework
Library             Process

*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}src${/}centreon_plugins.pl


*** Keywords ***
Start Mockoon
    [Arguments]    ${MOCKOON_JSON}    ${NAME_POLICY}
    ${process}    Start Process
    ...    mockoon-cli
    ...    start
    ...    --data
    ...    ${MOCKOON_JSON}
    ...    --port
    ...    3000
    ...    --pname
    ...    ${NAME_POLICY}
    Wait For Process    ${process}

Stop Mockoon
    [Arguments]    ${MOCKOON_POLICY}
    ${process}    Start Process
    ...    mockoon-cli
    ...    stop
    ...    ${MOCKOON_POLICY}
    Wait For Process    ${process}
