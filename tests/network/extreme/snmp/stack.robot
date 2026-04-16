*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::extreme::snmp::plugin


*** Test Cases ***
stack-x435-8p-4s ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=stack
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/extreme/snmp/x435-8p-4s
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options            expected_result    --
            ...      1     ${EMPTY}                   OK: Stacking is disable
