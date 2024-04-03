*** Settings ***
Documentation       Centreon Plugins for Robot Framework
Library             Process

*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}src${/}centreon_plugins.pl


*** Keywords ***
Start Mockoon
    [Arguments]    ${MOCKOON_JSON}
    ${process}    Start Process
    ...    mockoon-cli
    ...    start
    ...    --data
    ...    ${MOCKOON_JSON}
    ...    --port
    ...    3000
    Sleep    5s
git checkout -b MON-46772-external-pr-add-path-of-systemctl-on-the-gorgone-whitelist
Stop Mockoon
    Terminate All Processes