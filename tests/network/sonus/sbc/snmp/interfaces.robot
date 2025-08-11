*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::sonus::sbc::snmp::plugin


*** Test Cases ***
interfaces ${tc}
    [Tags]    network    sonus
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/sonus/sbc/snmp/slim_sonus-sbc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc     extra_options                                                                 expected_result    --
            ...      1      ${EMPTY}                                                                      CRITICAL: Interface 'Anonymized 073' Status : down (admin: up) - Interface 'Anonymized 232' Status : down (admin: up)
            ...      4      --oid-extra-display='ifName'                                                  CRITICAL: Interface 'Anonymized 073' [ Anonymized 073 ] Status : down (admin: up) - Interface 'Anonymized 232' [ Anonymized 232 ] Status : down (admin: up)
            ...      5      --display-transform-src='Anonymized 073' --display-transform-dst='toto'       CRITICAL: Interface 'toto' Status : down (admin: up) - Interface 'Anonymized 232' Status : down (admin: up)