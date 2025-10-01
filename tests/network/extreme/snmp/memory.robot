*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::extreme::snmp::plugin


*** Test Cases ***
memory-x435-8p-4s ${tc}
    [Tags]    network    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=memory
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/extreme/snmp/x435-8p-4s
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc      extra_options            expected_result    --
            ...      1     ${EMPTY}                   OK: Memory '1' Total: 512.00 MB Used: 324.71 MB (63.42%) Free: 187.29 MB (36.58%) | 'used'=340480000B;;;0;536870912
            ...      2     --warning-usage=0:0        WARNING: Memory '1' Total: 512.00 MB Used: 324.71 MB (63.42%) Free: 187.29 MB (36.58%) | 'used'=340480000B;0:0;;0;536870912
            ...      3     --critical-usage=0:0       CRITICAL: Memory '1' Total: 512.00 MB Used: 324.71 MB (63.42%) Free: 187.29 MB (36.58%) | 'used'=340480000B;;0:0;0;536870912
