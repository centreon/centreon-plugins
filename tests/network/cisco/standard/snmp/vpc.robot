*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
vpc ${tc}
    [Tags]    network    cisco    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=vpc
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-community=network/cisco/standard/snmp/cisco-vpc
    ...    ${extra_options}

    Ctn Run Command And Check Result As Regexp    ${command}    ${expected_regexp}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_regexp
    ...    --
    ...    1
    ...    --verbose
    ...    (?s).*peer '00:23:04:ee:be:51'.*peer '00:23:04:ee:be:51'.*peer '00:23:04:ee:be:51'.*peer '00:23:04:ee:be:51'.*
