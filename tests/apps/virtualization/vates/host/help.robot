*** Settings ***
Documentation       apps::virtualization::vates::host::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::virtualization::vates::host::plugin


*** Test Cases ***
Standard ${tc} - ${mode}
    [Tags]    apps    virtualization    host
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=${mode}
    ...    --help

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}    flags=IGNORECASE

    Examples:
    ...    tc
    ...    mode
    ...    expected_result
    ...    --
    ...    1
    ...    status
    ...    Mode:\n.*status
    ...    2
    ...    cpu
    ...    Mode:\n.*CPU
    ...    3
    ...    memory
    ...    Mode:\n.*[Mm]emory
