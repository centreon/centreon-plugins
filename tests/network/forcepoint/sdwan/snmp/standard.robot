*** Settings ***
Documentation       Forcepoint SD-WAN Standard SNMP Mode

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
Standard ${tc} - ${mode}
    [Tags]    network    forcepoint    sdwan    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=${mode}
    ...    --help

    # Only check that plugin knowns those modes because they are already tested with os::linux::snmp::plugin

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:        tc    mode                           expected_result    --
            ...      1     cpu                            ^Plugin Description:
            ...      2     cpu-detailed                   ^Plugin Description:
            ...      3     interfaces                     ^Plugin Description:
            ...      4     list-interfaces                ^Plugin Description:
            ...      5     load                           ^Plugin Description:
            ...      6     memory                         ^Plugin Description:
            ...      7     storage                        ^Plugin Description:
            ...      8     swap                           ^Plugin Description:
            ...      9     uptime                         ^Plugin Description:
