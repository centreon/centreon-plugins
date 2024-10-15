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

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --oid-display='ifName'                                                CRITICAL: Interface 'Anonymized 250' Status : down (admin: up) - Interface 'Anonymized 235' Status : down (admin: up) - Interface 'Anonymized 155' Status : down (admin: up) - Interface 'Anonymized 080' Status : down (admin: up) - Interface 'Anonymized 103' Status : down (admin: up)
            ...      2     --oid-extra-display='ifdesc'                                          CRITICAL: Interface 'Anonymized 250' [ Anonymized 147 ] Status : down (admin: up) - Interface 'Anonymized 235' [ Anonymized 094 ] Status : down (admin: up) - Interface 'Anonymized 155' [ Anonymized 130 ] Status : down (admin: up) - Interface 'Anonymized 080' [ Anonymized 221 ] Status : down (admin: up) - Interface 'Anonymized 103' [ Anonymized 017 ] Status : down (admin: up)
            ...      3     --display-transform-dst='ens' --display-transform-src='eth'           CRITICAL: Interface 'Anonymized 250' Status : down (admin: up) - Interface 'Anonymized 235' Status : down (admin: up) - Interface 'Anonymized 155' Status : down (admin: up) - Interface 'Anonymized 080' Status : down (admin: up) - Interface 'Anonymized 103' Status : down (admin: up)
            ...      4     --display-transform-dst='ens' --display-transform-src=''              CRITICAL: Interface 'ensAnonymized 250' Status : down (admin: up) - Interface 'ensAnonymized 235' Status : down (admin: up) - Interface 'ensAnonymized 155' Status : down (admin: up) - Interface 'ensAnonymized 080' Status : down (admin: up) - Interface 'ensAnonymized 103' Status : down (admin: up)
            ...      5     --verbose                                                             CRITICAL: Interface 'Anonymized 250' Status : down (admin: up) - Interface 'Anonymized 235' Status : down (admin: up) - Interface 'Anonymized 155' Status : down (admin: up) - Interface 'Anonymized 080' Status : down (admin: up) - Interface 'Anonymized 103' Status : down (admin: up) ${SPACE}Interface 'Anonymized 250' Status : down (admin: up) ${SPACE}Interface 'Anonymized 072' Status : up (admin: up) ${SPACE}Interface 'Anonymized 064' Status : up (admin: up) ${SPACE}Interface 'Anonymized 254' Status : up (admin: up) ${SPACE}Interface 'Anonymized 243' Status : up (admin: up) ${SPACE}Interface 'Anonymized 071' Status : down (admin: down) ${SPACE}Interface 'Anonymized 023' Status : down (admin: down) ${SPACE}Interface 'Anonymized 200' Status : down (admin: down) ${SPACE}Interface 'Anonymized 085' Status : down (admin: down) ${SPACE}Interface 'Anonymized 063' Status : down (admin: down) '\[ Message content over the limit has been removed. ]' ${SPACE}Interface 'Anonymized 138' Status : up (admin: up) ${SPACE}Interface 'Anonymized 232' Status : up (admin: up) ${SPACE}Interface 'Anonymized 189' Status : up (admin: up) ${SPACE}Interface 'Anonymized 103' Status : down (admin: up) ${SPACE}Interface 'Anonymized 165' Status : up (admin: up) ${SPACE}Interface 'Anonymized 057' Status : up (admin: up) ${SPACE}Interface 'Anonymized 081' Status : up (admin: up) ${SPACE}Interface 'Anonymized 033' Status : up (admin: up) ${SPACE}Interface 'Anonymized 048' Status : up (admin: up) ${SPACE}Interface 'Anonymized 196' Status : up (admin: up) ${SPACE}Interface 'Anonymized 016' Status : up (admin: up) ${SPACE}Interface 'Anonymized 233' Status : up (admin: up) ${SPACE}Interface 'Anonymized 127' Status : up (admin: up) ${SPACE}Interface 'Anonymized 146' Status : up (admin: up) ${SPACE}Interface 'Anonymized 166' Status : up (admin: up)