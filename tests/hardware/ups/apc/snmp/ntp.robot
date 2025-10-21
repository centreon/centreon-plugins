*** Settings ***
Documentation       Check UPS APC through SNMP

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${INJECT_PERL}     -Mntp_fixed_date -I${CURDIR}
${CMD}     ${CENTREON_PLUGINS}
    ...    --plugin=hardware::ups::apc::snmp::plugin
    ...    --mode=time
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-timeout=5


*** Test Cases ***
time ${tc}
    [Tags]    hardware    ups    apc    ntp

    ${OLD_PERL5OPT}=    Get Environment Variable     PERL5OPT   default=
    Set Environment Variable    PERL5OPT    ${INJECT_PERL} ${OLD_PERL5OPT}

    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=hardware/ups/apc/snmp/ntp
    ...    ${extra_options}

   Ctn Run Command Without Connector And Check Result As Strings    ${command}    ${expected_regexp}

    Examples:    tc    extra_options                  expected_regexp    --
    ...          1     ${EMPTY}                       OK: Time offset 32384 second(s): Local Time : 2025-08-26T08:50:07 (UTC) | 'time.offset.seconds'=32384s;;;;
    ...          2     --timezone='Europe/London'     OK: Time offset 28784 second(s): Local Time : 2025-08-26T08:50:07 (Europe/London) | 'time.offset.seconds'=28784s;;;;
    ...          3     --timezone='Europe/Paris'      OK: Time offset 25184 second(s): Local Time : 2025-08-26T08:50:07 (Europe/Paris) | 'time.offset.seconds'=25184s;;;;
    ...          4     --timezone='Japan/Tokyo'       UNKNOWN: Timezone 'Japan/Tokyo' does not exist.
    ...          5     --timezone='Asia/Tokyo'        OK: Time offset -16 second(s): Local Time : 2025-08-26T08:50:07 (Asia/Tokyo) | 'time.offset.seconds'=-16s;;;;
    ...          6     --warning-offset='0'           WARNING: Time offset 32384 second(s): Local Time : 2025-08-26T08:50:07 (UTC) | 'time.offset.seconds'=32384s;0:0;;;
    ...          7     --critical-offset='0'          CRITICAL: Time offset 32384 second(s): Local Time : 2025-08-26T08:50:07 (UTC) | 'time.offset.seconds'=32384s;;0:0;;
    ...          8     --timezone='doesnt/exist'      UNKNOWN: Timezone 'doesnt/exist' does not exist.
    ...          9     --timezone=':Europe/London'    OK: Time offset 28784 second(s): Local Time : 2025-08-26T08:50:07 (:Europe/London) | 'time.offset.seconds'=28784s;;;;
    ...         10     --timezone=':Asia/Tokyo'       OK: Time offset -16 second(s): Local Time : 2025-08-26T08:50:07 (:Asia/Tokyo) | 'time.offset.seconds'=-16s;;;;

