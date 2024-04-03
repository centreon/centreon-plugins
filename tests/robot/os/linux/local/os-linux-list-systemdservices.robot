*** Settings ***
Documentation       Linux Local list-systemdservices

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=os::linux::local::plugin
${COND}     ${PERCENT}\{sub\} =~ /exited/ && ${PERCENT}{display} =~ /network/'


*** Test Cases ***
List-Systemdservices v219 ${tc}/4
    [Documentation]    Systemd version < 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-systemdservices
    ...    --command-path=${CURDIR}${/}systemd-219
    ...    --filter-name='${filtername}'
    ...    --filter-description='${filterdescription}'

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:        tc    filtername                filterdescription            expected_result    --
            ...      1     toto                      ${EMPTY}                      List systemd services:
            ...      2     NetworkManager.service    ${EMPTY}                      List systemd services: \n\'NetworkManager.service\' [desc = Network Manager] [load = loaded] [active = active] [sub = running]
            ...      3     ${EMPTY}                   toto                         List systemd services:
            ...      4     ${EMPTY}                   Permit User Sessions         List systemd services: \n\'systemd-user-sessions.service\' [desc = Permit User Sessions] [load = loaded] [active = active] [sub = exited]

List-Systemdservices v252 ${tc}/4
    [Documentation]    Systemd version >= 248
    [Tags]    os    linux    local
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-systemdservices
    ...    --command-path=${CURDIR}${/}systemd-252
    ...    --filter-name='${filtername}'
    ...    --filter-description='${filterdescription}'

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    ${expected_result}
    ...    \nWrong output result for command:\n${command}\n\nExpected:\n${expected_result}\nCommand output:\n${output}\n

    Examples:        tc    filtername                filterdescription            expected_result    --
            ...      1     toto                      ${EMPTY}                      List systemd services:
            ...      2     NetworkManager.service    ${EMPTY}                      List systemd services: \n\'NetworkManager.service\' [desc = Network Manager] [load = loaded] [active = active] [sub = running]
            ...      3     ${EMPTY}                   toto                         List systemd services:
            ...      4     ${EMPTY}                   Permit User Sessions         List systemd services: \n\'systemd-user-sessions.service\' [desc = Permit User Sessions] [load = loaded] [active = active] [sub = exited]
