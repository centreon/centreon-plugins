*** Settings ***
Documentation       Check 3com equipment (old legacy. Maybe you should use 'network::h3c'plugin) in SNMP.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::3com::snmp::plugin


*** Test Cases ***
hardware ${tc}
    [Tags]    network    citrix    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/3com/snmp/3com-hardware-fake
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extra_options                                                         expected_result    --
            ...      1     --verbose                                                             CRITICAL: Fan '196611' status is deactive | 'count_fan'=2;;;; ${SPACE} Checking power supplies ${SPACE}Checking fans ${SPACE}Fan '65536' status is 'active' [instance: 65536] ${SPACE}Fan '196611' status is 'deactive' [instance: 196611]
            ...      2     --absent-problem=fan,2                                                CRITICAL: Fan '196611' status is deactive | 'count_fan'=2;;;;
            ...      3     --no-component                                                        CRITICAL: Fan '196611' status is deactive | 'count_fan'=2;;;;
            ...      4     --threshold-overload=''                                               CRITICAL: Fan '196611' status is deactive | 'count_fan'=2;;;;