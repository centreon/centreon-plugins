*** Settings ***
Documentation       apps::virtualization::vates::xenorchestra::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=apps::virtualization::vates::xenorchestra::plugin


*** Test Cases ***
Standard ${tc} - ${mode}
    [Tags]    apps    virtualization    xenorchestra
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
    ...    vm-status
    ...    Mode:\n.*virtual machines status
    ...    2
    ...    storage-repository
    ...    Mode:\n.*Storage repository status
    ...    3
    ...    list-storage-repository
    ...    Mode:\n.*storage repositories.*for service\n.*discovery
