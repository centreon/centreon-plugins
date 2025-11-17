*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
list-replications ${tc}
    [Tags]    snmp    storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-replications
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options           expected_result    --
            ...      1     --verbose               List replications: [index = 1][type = 1][source = Anonymized 127][destination = Anonymized 057][state = normal][status = idle][initiator = 0] [index = 2][type = 2][source = Anonymized 224][destination = Anonymized 079][state = normal][status = idle][initiator = 0] [index = 3][type = 3][source = Anonymized 016][destination = Anonymized 146][state = normal][status = idle][initiator = 0]
