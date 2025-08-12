*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown

*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::sonus::sbc::snmp::plugin


*** Test Cases ***
call-statistics ${tc}
    [Tags]    network    sonus
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=call-statistics
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/sonus/sbc/snmp/slim_sonus-sbc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc     extra_options                                                              expected_result    --
            ...      1      ${EMPTY}                                                                   OK: All ports call statistics are ok | '1#port.calls.current.count'=5;;;0; '2#port.calls.current.count'=7;;;0; '3#port.calls.current.count'=9;;;0;
            ...      2      --warning-current=5 --critical-current=7                                   CRITICAL: Port '3' number of calls current: 9 WARNING: Port '2' number of calls current: 7 | '1#port.calls.current.count'=5;0:5;0:7;0; '1#port.calls.total.count'=0;;;0; '1#port.calls.connected.count'=0;;;0; '1#port.calls.refused.count'=0;;;0; '1#port.calls.errored.count'=0;;;0; '1#port.calls.blocked.count'=0;;;0; '2#port.calls.current.count'=7;0:5;0:7;0; '2#port.calls.total.count'=0;;;0; '2#port.calls.connected.count'=0;;;0; '2#port.calls.refused.count'=0;;;0; '2#port.calls.errored.count'=0;;;0; '2#port.calls.blocked.count'=0;;;0; '3#port.calls.current.count'=9;0:5;0:7;0; '3#port.calls.total.count'=0;;;0; '3#port.calls.connected.count'=0;;;0; '3#port.calls.refused.count'=0;;;0; '3#port.calls.errored.count'=0;;;0; '3#port.calls.blocked.count'=0;;;0;
            ...      3      --warning-total=0 --critical-total=10                                      OK: All ports call statistics are ok | '1#port.calls.current.count'=5;;;0; '1#port.calls.total.count'=0;0:0;0:10;0; '1#port.calls.connected.count'=0;;;0; '1#port.calls.refused.count'=0;;;0; '1#port.calls.errored.count'=0;;;0; '1#port.calls.blocked.count'=0;;;0; '2#port.calls.current.count'=7;;;0; '2#port.calls.total.count'=0;0:0;0:10;0; '2#port.calls.connected.count'=0;;;0; '2#port.calls.refused.count'=0;;;0; '2#port.calls.errored.count'=0;;;0; '2#port.calls.blocked.count'=0;;;0; '3#port.calls.current.count'=9;;;0; '3#port.calls.total.count'=0;0:0;0:10;0; '3#port.calls.connected.count'=0;;;0; '3#port.calls.refused.count'=0;;;0; '3#port.calls.errored.count'=0;;;0; '3#port.calls.blocked.count'=0;;;0;
            ...      4      --warning-current=5 --critical-current=''                                  WARNING: Port '2' number of calls current: 7 - Port '3' number of calls current: 9 | '1#port.calls.current.count'=5;0:5;;0; '1#port.calls.total.count'=0;;;0; '1#port.calls.connected.count'=0;;;0; '1#port.calls.refused.count'=0;;;0; '1#port.calls.errored.count'=0;;;0; '1#port.calls.blocked.count'=0;;;0; '2#port.calls.current.count'=7;0:5;;0; '2#port.calls.total.count'=0;;;0; '2#port.calls.connected.count'=0;;;0; '2#port.calls.refused.count'=0;;;0; '2#port.calls.errored.count'=0;;;0; '2#port.calls.blocked.count'=0;;;0; '3#port.calls.current.count'=9;0:5;;0; '3#port.calls.total.count'=0;;;0; '3#port.calls.connected.count'=0;;;0; '3#port.calls.refused.count'=0;;;0; '3#port.calls.errored.count'=0;;;0; '3#port.calls.blocked.count'=0;;;0;
