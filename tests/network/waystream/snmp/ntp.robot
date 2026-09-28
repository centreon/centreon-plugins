*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -Mntp_fixed_date -I${CURDIR}
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::waystream::snmp::plugin
...                 --mode=ntp
...                 --hostname=${HOSTNAME}
...                 --snmp-port=${SNMPPORT}


*** Test Cases ***
Ntp MS4000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms4000
    ...    ${extra_options}

    ${OLD_PERL5OPT}    Get Environment Variable    PERL5OPT    default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Time offset 6 second(s): Local Time : 2025-12-16T07:47:39 (-0100) | 'time.offset.seconds'=6s;;;;
    ...    2
    ...    --warning-offset=1
    ...    WARNING: Time offset 6 second(s): Local Time : 2025-12-16T07:47:39 (-0100) | 'time.offset.seconds'=6s;0:1;;;
    ...    3
    ...    --critical-offset=1
    ...    CRITICAL: Time offset 6 second(s): Local Time : 2025-12-16T07:47:39 (-0100) | 'time.offset.seconds'=6s;;0:1;;

Ntp MS7000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms7000
    ...    ${extra_options}

    ${OLD_PERL5OPT}    Get Environment Variable    PERL5OPT    default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Time offset 391 second(s): Local Time : 2025-12-16T07:54:04 (-0100) | 'time.offset.seconds'=391s;;;;
    ...    2
    ...    --warning-offset=1
    ...    WARNING: Time offset 391 second(s): Local Time : 2025-12-16T07:54:04 (-0100) | 'time.offset.seconds'=391s;0:1;;;
    ...    3
    ...    --critical-offset=1
    ...    CRITICAL: Time offset 391 second(s): Local Time : 2025-12-16T07:54:04 (-0100) | 'time.offset.seconds'=391s;;0:1;;
