*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::sonus::sbc::snmp::plugin


*** Test Cases ***
list-interfaces ${tc}
    [Tags]    network    sonus
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/sonus/sbc/snmp/slim_sonus-sbc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc     extra_options                                                                 expected_result    --
            ...      1      ${EMPTY} --name --interface='Anonymized 049'                                  List interfaces: 'Anonymized 049' [speed = ][status = up][id = 1078199296][type = voiceFXS] 'Anonymized 049' [speed = ][status = up][id = 1079510016][type = voiceFXS]
            ...      2      --name --interface='Anonymized 25' --skip-speed0                              List interfaces: skipping interface 'Anonymized 252': interface speed is 0 and option --skip-speed0 is set
            ...      6      --filter-status='down' --name --interface='Anonymized 049'                    List interfaces: skipping interface 'Anonymized 049': no matching filter status skipping interface 'Anonymized 049': no matching filter status
            ...      7      --filter-status='down' --skip-speed0 --name --interface='Anonymized 049'      List interfaces: skipping interface 'Anonymized 049': interface speed is 0 and option --skip-speed0 is set skipping interface 'Anonymized 049': interface speed is 0 and option --skip-speed0 is set
