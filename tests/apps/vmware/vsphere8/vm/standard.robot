*** Settings ***
Documentation       Forcepoint SD-WAN Standard SNMP Mode

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=apps::vmware::vsphere8::vm::plugin

*** Test Cases ***
Standard ${tc} - ${mode}
    [Tags]    apps    api    vmware   vsphere8    vm
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=${mode}
    ...    --help

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:        tc    mode          expected_result    --
            ...      1     cpu           ^Plugin Description:
            ...      2     discovery     ^Plugin Description:
            ...      3     memory        ^Plugin Description:
            ...      4     vm-status     ^Plugin Description:
            ...      5     vm-tools      ^Plugin Description:
            ...      6     disk-io       ^Plugin Description:
            ...      7     network       ^Plugin Description:
            ...      8     power         ^Plugin Description:
