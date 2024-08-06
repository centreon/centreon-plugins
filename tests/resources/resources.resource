*** Settings ***
Documentation       Centreon Plugins for Robot Framework

Library             Process


*** Variables ***
${CENTREON_PLUGINS}     perl ${CURDIR}${/}..${/}..${/}src${/}centreon_plugins.pl
# one we use package, we need to remove the "perl" part to be sure the plugin is executable and is correctly formated
# with a shebang at the top.
${HOSTNAME}             127.0.0.1
${APIPORT}              3000
${SNMPPORT}             2024
${SNMPVERSION}          2c
${PERCENT}              %


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

Ctn Run Command And Check Result As Strings
    [Arguments]    ${command}    ${expected_result}
    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${expected_result}
    ...    ${output}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True