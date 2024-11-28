*** Settings ***
Documentation       Check EMC DataDomain in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=storage::emc::datadomain::snmp::plugin


*** Test Cases ***
list-filesystems ${tc}
    [Tags]    snmp  storage
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=list-filesystems
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=storage/emc/datadomain/snmp/slim-datadomain
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                   expected_result    --
            ...      1     --verbose                       List filesystems: [name = /ddvar][total = 50036368998][used = 11274289152] [name = /ddvar/core][total = 584867171532][used = 107374182] [name = Anonymized 056][total = 90263462189465][used = 53328461430784] [name = Anonymized 157][total = 755377373183][used = 533971809075] [name = Anonymized 246][total = 988878746314342][used = 988878746314342] 
