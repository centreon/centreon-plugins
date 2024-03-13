*** Settings ***
Documentation       Linux Local list-systemdservices

Library             OperatingSystem
Library             String
Library             Examples

Test Timeout        120s


*** Variables ***
${CENTREON_PLUGINS}         ${CURDIR}${/}..${/}..${/}..${/}src${/}centreon_plugins.pl

${CMD}                      perl ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin
${PERCENT}                  %

${COND}                     ${PERCENT}\{sub\} =~ /exited/ && ${PERCENT}{display} =~ /network/'

*** Test Cases ***
List-Systemdservices v219 ${tc}/4
    [Documentation]    Systemd version < 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-systemdservices
    ...    --command-path=${CURDIR}${/}..${/}..${/}resources${/}linux${/}systemd-219

    # Test simple usage of the systemd-sc-status mode

    # Append options to command
    ${command}     Append Option To Command    ${command}     --filter-name             ${filtername}
    ${command}     Append Option To Command    ${command}     --filter-description      ${filterdescription}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:        tc    filtername                filterdescription            expected_result    --
            ...      1     toto                      _empty_                      List systemd services:
            ...      2     NetworkManager.service    _empty_                      List systemd services: \n\'NetworkManager.service\' [desc = Network Manager] [load = loaded] [active = active] [sub = running]
            ...      3     _empty_                   toto                         List systemd services:
            ...      4     _empty_                   Permit User Sessions         List systemd services: \n\'systemd-user-sessions.service\' [desc = Permit User Sessions] [load = loaded] [active = active] [sub = exited]

List-Systemdservices v252 ${tc}/4
    [Documentation]    Systemd version >= 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-systemdservices
    ...    --command-path=${CURDIR}${/}..${/}..${/}resources${/}linux${/}systemd-252

    # Test simple usage of the systemd-sc-status mode

    # Append options to command
    ${command}     Append Option To Command    ${command}     --filter-name             ${filtername}
    ${command}     Append Option To Command    ${command}     --filter-description      ${filterdescription}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:        tc    filtername                filterdescription            expected_result    --
            ...      1     toto                      _empty_                      List systemd services:
            ...      2     NetworkManager.service    _empty_                      List systemd services: \n\'NetworkManager.service\' [desc = Network Manager] [load = loaded] [active = active] [sub = running]
            ...      3     _empty_                   toto                         List systemd services:
            ...      4     _empty_                   Permit User Sessions         List systemd services: \n\'systemd-user-sessions.service\' [desc = Permit User Sessions] [load = loaded] [active = active] [sub = exited]

*** Keywords ***
Append Option To Command
    [Documentation]    Concatenates the first argument (option) with the second (value) after having replaced the value with "" if its content is '_empty_'
    [Arguments]    ${command}    ${option}    ${value}
    ${value}    Set Variable If    '${value}' == '_empty_'    ''    '${value}'
    [return]    ${command} ${option}=${value}

