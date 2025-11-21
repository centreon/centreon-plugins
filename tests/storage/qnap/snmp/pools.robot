*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=storage::qnap::snmp::plugin
...         --mode=pools
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=storage/qnap/snmp/qnap


*** Test Cases ***
Pools ${tc}
    [Tags]    storage    qnap    pools
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                                   expected_result    --
            ...      1     ${EMPTY}                                                                        OK: pool '1' status: ready
            ...      2     --filter-name=1                                                                 OK: pool '1' status: ready
            ...      3     --unknown-pool-status='\\\%{status} eq "ready"'                                 UNKNOWN: pool '1' status: ready
            ...      4     --warning-pool-status='\\\%{status} eq "ready"'                                 WARNING: pool '1' status: ready
            ...      5     --critical-pool-status='\\\%{status} eq "ready"'                                CRITICAL: pool '1' status: ready
