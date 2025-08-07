*** Settings ***
Documentation       Check EMC DataDomain in SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
interfaces ${tc}
    [Tags]    snmp  storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=interfaces
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                               expected_result    --
            ...      1     --verbose                                                                   OK: All interfaces are ok Interface 'lo' Status : up (admin: up) Interface 'Anonymized 012' Status : up (admin: up) Interface 'Anonymized 118' Status : down (admin: down) Interface 'Anonymized 073' Status : down (admin: down) Interface 'Anonymized 071' Status : up (admin: up) Interface 'Anonymized 073' Status : up (admin: up) Interface 'Anonymized 232' Status : up (admin: up) Interface 'Anonymized 191' Status : up (admin: up) Interface 'Anonymized 242' Status : up (admin: up) Interface 'Anonymized 175' Status : up (admin: up) Interface 'Anonymized 128' Status : up (admin: up) Interface 'Anonymized 037' Status : down (admin: down) Interface 'Anonymized 184' Status : down (admin: down) Interface 'Anonymized 252' Status : down (admin: down) Interface 'Anonymized 012' Status : down (admin: down) Interface 'Anonymized 232' Status : up (admin: up) Interface 'Anonymized 072' Status : up (admin: up) Interface 'Anonymized 037' Status : up (admin: up) 
            ...      2     --oid-display='ifName'                                                      OK: All interfaces are ok
            ...      3     --oid-extra-display='ifDesc'                                                OK: All interfaces are ok
            ...      4     --display-transform-src='eth' --display-transform-dst='ens'                 OK: All interfaces are ok
