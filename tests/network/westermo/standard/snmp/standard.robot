*** Settings ***
Documentation       network::westermo::standard::snmp::plugin

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::westermo::standard::snmp::plugin


*** Test Cases ***
Standard ${tc} - ${mode}
    [Tags]    network    forcepoint    sdwan    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=${mode}
    ...    --help

    # Only check that plugin knowns those modes because they are already tested with os::linux::snmp::plugin

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_result}

    Examples:    tc    mode    expected_result    --
    ...    1    cpu    ^Plugin Description:
    ...    2    interfaces    ^Plugin Description:
    ...    3    list-interfaces    ^Plugin Description:
    ...    4    list-spanning-trees    ^Plugin Description:
    ...    5    memory    ^Plugin Description:
    ...    6    sensors    ^Plugin Description:
    ...    7    spanning-tree    ^Plugin Description:
    ...    8    tcpcon    ^Plugin Description:
    ...    9    udpcon    ^Plugin Description:
    ...   10    uptime    ^Plugin Description:
