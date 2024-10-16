*** Settings ***
Documentation       Network citrix netscaler health

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::cisco::standard::snmp::plugin


*** Test Cases ***
interfaces ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/cisco/standard/snmp/cisco
    ...    ${extra_options}

    ${output}    Run    ${command}
    ${output}    Strip String    ${output}
    Should Contain    
    ...    ${output}    
    ...    ${expected_result}
    ...    Wrong output result for command:\n${command}\n\nObtained:\n${output}\n\nExpected:\n${expected_result}\n
    ...    values=False
    ...    collapse_spaces=True

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --oid-display='ifName'                                                CRITICAL: Interface 'Anonymized 250' Status : down (admin: up) - Interface 'Anonymized 235' Status : down (admin: up) - Interface 'Anonymized 155' Status : down (admin: up) - Interface 'Anonymized 080' Status : down (admin: up) - Interface 'Anonymized 103' Status : down (admin: up)
            ...      2     --oid-extra-display='ifdesc'                                          CRITICAL: Interface 'Anonymized 250' [ Anonymized 147 ] Status : down (admin: up) - Interface 'Anonymized 235' [ Anonymized 094 ] Status : down (admin: up) - Interface 'Anonymized 155' [ Anonymized 130 ] Status : down (admin: up) - Interface 'Anonymized 080' [ Anonymized 221 ] Status : down (admin: up) - Interface 'Anonymized 103' [ Anonymized 017 ] Status : down (admin: up)
            ...      3     --display-transform-dst='ens' --display-transform-src='eth'           CRITICAL: Interface 'Anonymized 250' Status : down (admin: up) - Interface 'Anonymized 235' Status : down (admin: up) - Interface 'Anonymized 155' Status : down (admin: up) - Interface 'Anonymized 080' Status : down (admin: up) - Interface 'Anonymized 103' Status : down (admin: up)
            ...      4     --display-transform-dst='ens' --display-transform-src=''              CRITICAL: Interface 'ensAnonymized 250' Status : down (admin: up) - Interface 'ensAnonymized 235' Status : down (admin: up) - Interface 'ensAnonymized 155' Status : down (admin: up) - Interface 'ensAnonymized 080' Status : down (admin: up) - Interface 'ensAnonymized 103' Status : down (admin: up)