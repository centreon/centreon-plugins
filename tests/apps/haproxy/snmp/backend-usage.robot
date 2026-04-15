*** Settings ***
Documentation       apps::haproxy::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=apps::haproxy::snmp::plugin
...         --mode=backend-usage
...         --hostname=${HOSTNAME}
...         --snmp-version=${SNMPVERSION}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Backend-usage-legacy ${tc}
    [Tags]    apps    haproxy    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=apps/haproxy/snmp/haproxy-legacy
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Backend 'bk_web' status: UP, current queue: 2, current sessions: 1, total-sessions : Buffer creation, traffic-in : Buffer creation, traffic-out : Buffer creation | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0;
    ...    2
    ...    --filter-counters=NONE
    ...    OK: Backend 'bk_web'
    ...    3
    ...    --filter-name=NONE
    ...    UNKNOWN: No backend found.
    ...    4
    ...    --warning-current-queue=0
    ...    WARNING: Backend 'bk_web' current queue: 2 | 'bk_web#backend.queue.current.count'=2;0:0;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    5
    ...    --critical-current-queue=0
    ...    CRITICAL: Backend 'bk_web' current queue: 2 | 'bk_web#backend.queue.current.count'=2;;0:0;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    6
    ...    --warning-current-sessions=0
    ...    WARNING: Backend 'bk_web' current sessions: 1 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;0:0;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    7
    ...    --critical-current-sessions=0
    ...    CRITICAL: Backend 'bk_web' current sessions: 1 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;0:0;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    8
    ...    --warning-status='%\\\{status\\\} =~ /UP/'
    ...    WARNING: Backend 'bk_web' status: UP | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    9
    ...    --critical-status='%\\\{status\\\} =~ /UP/'
    ...    CRITICAL: Backend 'bk_web' status: UP | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    10
    ...    --warning-total-sessions=1:
    ...    WARNING: Backend 'bk_web' total sessions: 0 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;1:;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    11
    ...    --critical-total-sessions=1:
    ...    CRITICAL: Backend 'bk_web' total sessions: 0 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;1:;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    12
    ...    --warning-traffic-in=1:
    ...    WARNING: Backend 'bk_web' traffic in: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;1:;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    13
    ...    --critical-traffic-in=1:
    ...    CRITICAL: Backend 'bk_web' traffic in: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;1:;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    14
    ...    --warning-traffic-out=1:
    ...    WARNING: Backend 'bk_web' traffic out: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;1:;;0;
    ...    15
    ...    --critical-traffic-out=1:
    ...    CRITICAL: Backend 'bk_web' traffic out: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;1:;0;

*** Test Cases ***
Backend-usage-new ${tc}
    [Tags]    apps    haproxy    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=apps/haproxy/snmp/haproxy
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Backend 'bk_web' status: UP, current queue: 2, current sessions: 1, total sessions: 0, traffic in: 0.00 b/s, traffic out: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    2
    ...    --filter-counters=NONE
    ...    OK: Backend 'bk_web'
    ...    3
    ...    --filter-name=NONE
    ...    UNKNOWN: No backend found.
    ...    4
    ...    --warning-current-queue=0
    ...    WARNING: Backend 'bk_web' current queue: 2 | 'bk_web#backend.queue.current.count'=2;0:0;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    5
    ...    --critical-current-queue=0
    ...    CRITICAL: Backend 'bk_web' current queue: 2 | 'bk_web#backend.queue.current.count'=2;;0:0;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    6
    ...    --warning-current-sessions=0
    ...    WARNING: Backend 'bk_web' current sessions: 1 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;0:0;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    7
    ...    --critical-current-sessions=0
    ...    CRITICAL: Backend 'bk_web' current sessions: 1 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;0:0;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    8
    ...    --warning-status='%\\\{status\\\} =~ /UP/'
    ...    WARNING: Backend 'bk_web' status: UP | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    9
    ...    --critical-status='%\\\{status\\\} =~ /UP/'
    ...    CRITICAL: Backend 'bk_web' status: UP | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    10
    ...    --warning-total-sessions=1:
    ...    WARNING: Backend 'bk_web' total sessions: 0 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;1:;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    11
    ...    --critical-total-sessions=1:
    ...    CRITICAL: Backend 'bk_web' total sessions: 0 | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;1:;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    12
    ...    --warning-traffic-in=1:
    ...    WARNING: Backend 'bk_web' traffic in: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;1:;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    13
    ...    --critical-traffic-in=1:
    ...    CRITICAL: Backend 'bk_web' traffic in: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;1:;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;;0;
    ...    14
    ...    --warning-traffic-out=1:
    ...    WARNING: Backend 'bk_web' traffic out: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;1:;;0;
    ...    15
    ...    --critical-traffic-out=1:
    ...    CRITICAL: Backend 'bk_web' traffic out: 0.00 b/s | 'bk_web#backend.queue.current.count'=2;;;0; 'bk_web#backend.sessions.current.count'=1;;;0; 'bk_web#backend.sessions.total.count'=0;;;0; 'bk_web#backend.traffic.in.bitpersecond'=0.00b/s;;;0; 'bk_web#backend.traffic.out.bitpersecond'=0.00b/s;;1:;0;
