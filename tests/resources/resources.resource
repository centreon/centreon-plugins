*** Settings ***
Documentation       Centreon Plugins for Robot Framework
Library             Process

*** Variables ***
${CENTREON_PLUGINS}         perl ${CURDIR}${/}..${/}..${/}src${/}centreon_plugins.pl
# one we use package, we need to remove the "perl" part to be sure the plugin is executable and is correctly formated
# with a shebang at the top.
${PERCENT}                  %

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
    Sleep    10s
Stop Mockoon
    Terminate All Processes