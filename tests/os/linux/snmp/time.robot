*** Settings ***
Documentation       os::linux::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}      -Mfixed_date -I${CURDIR}
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=os::linux::snmp::plugin
...                 --mode=time
...                 --hostname=${HOSTNAME}
...                 --snmp-port=${SNMPPORT}
...                 --snmp-community=os/linux/snmp/linux
${CGS_CMD}          ${CENTREON_GENERIC_SNMP}


*** Test Cases ***
time/ntp ${tc}
    [Tags]    os    linux    snmp
    ${command}    Catenate
    ...    ${CMD}
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
    ...    OK: Time offset -9 second(s): Local Time : 2024-08-13T10:39:44 (+0200) | 'offset'=-9s;;;;
    ...    2
    ...    --warning-offset=1
    ...    WARNING: Time offset -9 second(s): Local Time : 2024-08-13T10:39:44 (+0200) | 'offset'=-9s;0:1;;;
    ...    3
    ...    --critical-offset=1
    ...    CRITICAL: Time offset -9 second(s): Local Time : 2024-08-13T10:39:44 (+0200) | 'offset'=-9s;;0:1;;
    ...    4
    ...    --timezone='+0100'
    ...    OK: Time offset 3591 second(s): Local Time : 2024-08-13T10:39:44 (+0100) | 'offset'=3591s;;;;
