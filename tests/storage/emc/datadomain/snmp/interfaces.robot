*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
interfaces ${tc}
    [Tags]    snmp    storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                              expected_result    --
            ...      1     ${EMPTY}                                                                   OK: All interfaces are ok
            ...      2     --interface='Anonymized 012' --name --add-traffic                          OK: All interfaces are ok
            ...      3     --interface='Anonymized 012' --name --add-traffic                          OK: All interfaces are ok | 'Anonymized 012#interface.traffic.in.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 012#interface.traffic.out.bitspersecond'=0.00b/s;;;0;10000000000 'Anonymized 012#interface.traffic.in.bitspersecond'=0.00b/s;;;0; 'Anonymized 012#interface.traffic.out.bitspersecond'=0.00b/s;;;0;
