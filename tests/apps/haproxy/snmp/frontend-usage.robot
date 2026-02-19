*** Settings ***
Documentation       apps::haproxy::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=apps::haproxy::snmp::plugin
...         --mode=frontend-usage
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-version=${SNMPVERSION}

*** Test Cases ***
Frontend-usage-legacy ${tc}
    [Tags]    apps    haproxy    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=apps/haproxy/snmp/haproxy-front-legacy
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Frontend 'frontend' status: OPEN, current sessions: 24, total-sessions : Buffer creation, traffic-in : Buffer creation, traffic-out : Buffer creation | 'frontend#frontend.sessions.current.count'=24;;;0;
    ...    2
    ...    --filter-counters=NONE
    ...    OK: Frontend 'frontend'
    ...    3
    ...    --filter-name=NONE
    ...    UNKNOWN: No frontend found.
    ...    4
    ...    --warning-current-sessions=0
    ...    WARNING: Frontend 'frontend' current sessions: 24 | 'frontend#frontend.sessions.current.count'=24;0:0;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    5
    ...    --critical-current-sessions=0
    ...    CRITICAL: Frontend 'frontend' current sessions: 24 | 'frontend#frontend.sessions.current.count'=24;;0:0;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    6
    ...    --warning-status='%\\\{status\\\} =~ /OPEN/'
    ...    WARNING: Frontend 'frontend' status: OPEN | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    7
    ...    --critical-status='%\\\{status\\\} =~ /OPEN/'
    ...    CRITICAL: Frontend 'frontend' status: OPEN | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    8
    ...    --warning-total-sessions=1:
    ...    WARNING: Frontend 'frontend' total sessions: 0 | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;1:;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    9
    ...    --critical-total-sessions=1:
    ...    CRITICAL: Frontend 'frontend' total sessions: 0 | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;1:;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    10
    ...    --warning-traffic-in=1:
    ...    WARNING: Frontend 'frontend' traffic in: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;1:;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    11
    ...    --critical-traffic-in=1:
    ...    CRITICAL: Frontend 'frontend' traffic in: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;1:;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    12
    ...    --warning-traffic-out=1:
    ...    WARNING: Frontend 'frontend' traffic out: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;1:;;0;
    ...    13
    ...    --critical-traffic-out=1:
    ...    CRITICAL: Frontend 'frontend' traffic out: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;1:;0;

*** Test Cases ***
Frontend-usage ${tc}
    [Tags]    apps    haproxy    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=apps/haproxy/snmp/haproxy-front
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Frontend 'frontend' status: OPEN, current sessions: 24, total sessions: 0, traffic in: 0.00 b/s, traffic out: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    2
    ...    --filter-counters=NONE
    ...    OK: Frontend 'frontend'
    ...    3
    ...    --filter-name=NONE
    ...    UNKNOWN: No frontend found.
    ...    4
    ...    --warning-current-sessions=0
    ...    WARNING: Frontend 'frontend' current sessions: 24 | 'frontend#frontend.sessions.current.count'=24;0:0;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    5
    ...    --critical-current-sessions=0
    ...    CRITICAL: Frontend 'frontend' current sessions: 24 | 'frontend#frontend.sessions.current.count'=24;;0:0;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    6
    ...    --warning-status='%\\\{status\\\} =~ /OPEN/'
    ...    WARNING: Frontend 'frontend' status: OPEN | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    7
    ...    --critical-status='%\\\{status\\\} =~ /OPEN/'
    ...    CRITICAL: Frontend 'frontend' status: OPEN | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    8
    ...    --warning-total-sessions=1:
    ...    WARNING: Frontend 'frontend' total sessions: 0 | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;1:;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    9
    ...    --critical-total-sessions=1:
    ...    CRITICAL: Frontend 'frontend' total sessions: 0 | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;1:;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    10
    ...    --warning-traffic-in=1:
    ...    WARNING: Frontend 'frontend' traffic in: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;1:;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    11
    ...    --critical-traffic-in=1:
    ...    CRITICAL: Frontend 'frontend' traffic in: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;1:;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    12
    ...    --warning-traffic-out=1:
    ...    WARNING: Frontend 'frontend' traffic out: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;1:;;0;
    ...    13
    ...    --critical-traffic-out=1:
    ...    CRITICAL: Frontend 'frontend' traffic out: 0.00 b/s | 'frontend#frontend.sessions.current.count'=24;;;0; 'frontend#frontend.sessions.total.count'=0;;;0; 'frontend#frontend.traffic.in.bitpersecond'=0.00b/s;;;0; 'frontend#frontend.traffic.out.bitpersecond'=0.00b/s;;1:;0;
