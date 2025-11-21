*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=storage::qnap::snmp::plugin
...         --mode=volumes
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=storage/qnap/snmp/qnap


*** Test Cases ***
volumes ${tc}
    [Tags]    storage    qnap    volumes
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                   expected_result    --
            ...      1     ${EMPTY}                                                        OK: All volumes are ok
            ...      2     --filter-name="Anonymized 227"                                  OK: volume 'Anonymized 227' status: Anonymized 103
            ...      3     --unknown-volume-status='\\\%{status} eq "Anonymized 145"'      UNKNOWN: volume 'Anonymized 004' status: Anonymized 145
            ...      4     --warning-volume-status='\\\%{status} eq "Anonymized 185"'      WARNING: volume 'Anonymized 180' status: Anonymized 185
            ...      5     --critical-volume-status='\\\%{status} eq "Anonymized 103"'     CRITICAL: volume 'Anonymized 227' status: Anonymized 103
