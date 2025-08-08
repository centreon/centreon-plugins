*** Settings ***
Documentation       Check Windows operating systems in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}

*** Test Cases ***
interfaces ${tc}
    [Tags]    os    Windows
    ${command}    Catenate
    ...    ${CMD}
    ...    --plugin=os::windows::snmp::plugin
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=os/windows/snmp/interfaces
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                    expected_result    --
            ...      1     --verbose                                                        CRITICAL: Interface 'Anonymized 232' Status : down (admin: up) - Interface 'Anonymized 184' Status : down (admin: up) - Interface 'Anonymized 101' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 232' Status : down (admin: up) - Interface 'Anonymized 072' Status : down (admin: up)${SPACE}Interface 'Anonymized 250' Status : up (admin: up)${SPACE}Interface 'Anonymized 012' Status : notPresent (admin: down)${SPACE}Interface 'Anonymized 118' Status : notPresent (admin: down)${SPACE}Interface 'Anonymized 073' Status : up (admin: up)${SPACE}Interface 'Anonymized 071' Status : up (admin: up)${SPACE}Interface 'Anonymized 073' Status : up (admin: up)${SPACE}Interface 'Anonymized 232' Status : down (admin: up)${SPACE}Interface 'Anonymized 191' Status : up (admin: up)${SPACE}Interface 'Anonymized 242' Status : up (admin: up)${SPACE}Interface 'Anonymized 175' Status : up (admin: up)${SPACE}Interface 'Anonymized 128' Status : up (admin: up)${SPACE}Interface 'Anonymized 037' Status : notPresent (admin: down)${SPACE}Interface 'Anonymized 080' Status : up (admin: up)${SPACE}Interface 'Anonymized 229' Status : up (admin: up)${SPACE}Interface 'Anonymized 248' Status : up (admin: up)${SPACE}Interface 'Anonymized 092' Status : up (admin: up)${SPACE}Interface 'Anonymized 187' Status : up (admin: up)${SPACE}Interface 'Anonymized 184' Status : down (admin: up)${SPACE}Interface 'Anonymized 101' Status : down (admin: up)${SPACE}Interface 'Anonymized 252' Status : notPresent (admin: down)${SPACE}Interface 'Anonymized 012' Status : down (admin: up)${SPACE}Interface 'Anonymized 232' Status : down (admin: up)${SPACE}Interface 'Anonymized 072' Status : down (admin: up)${SPACE}Interface 'Anonymized 037' Status : up (admin: up)
            ...      2     --display-transform-src='eth' --display-transform-dst='ens'      CRITICAL: Interface 'Anonymized 232' Status : down (admin: up) - Interface 'Anonymized 184' Status : down (admin: up) - Interface 'Anonymized 101' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 232' Status : down (admin: up) - Interface 'Anonymized 072' Status : down (admin: up)
            ...      3     --oid-display='ifName'                                           CRITICAL: Interface 'Anonymized 232' Status : down (admin: up) - Interface 'Anonymized 184' Status : down (admin: up) - Interface 'Anonymized 101' Status : down (admin: up) - Interface 'Anonymized 012' Status : down (admin: up) - Interface 'Anonymized 232' Status : down (admin: up) - Interface 'Anonymized 072' Status : down (admin: up)
            ...      4     --oid-extra-display='ifDesc'                                     CRITICAL: Interface 'Anonymized 232' [ WAN Miniport (L2TP) ] Status : down (admin: up) - Interface 'Anonymized 184' [ WAN Miniport (IKEv2) ] Status : down (admin: up) - Interface 'Anonymized 101' [ WAN Miniport (SSTP) ] Status : down (admin: up) - Interface 'Anonymized 012' [ WAN Miniport (GRE) ] Status : down (admin: up) - Interface 'Anonymized 232' [ WAN Miniport (PPPOE) ] Status : down (admin: up) - Interface 'Anonymized 072' [ WAN Miniport (PPTP) ] Status : down (admin: up)
