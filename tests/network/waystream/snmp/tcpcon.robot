*** Settings ***
Documentation       network::waystream::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=network::waystream::snmp::plugin
...         --mode=tcpcon
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}


*** Test Cases ***
Tcpcon MS4000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms4000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Total connections: 6 | 'total#service.connections.tcp.count'=6;;;0; 'connections.tcp.closewait.count'=0;;;0; 'connections.tcp.closed.count'=0;;;0; 'connections.tcp.closing.count'=0;;;0; 'connections.tcp.established.count'=6;;;0; 'connections.tcp.finwait1.count'=0;;;0; 'connections.tcp.finwait2.count'=0;;;0; 'connections.tcp.lastack.count'=0;;;0; 'connections.tcp.listen.count'=3;;;0; 'connections.tcp.synreceived.count'=0;;;0; 'connections.tcp.synsent.count'=0;;;0; 'connections.tcp.timewait.count'=0;;;0;
    ...    2
    ...    --warning=1
    ...    WARNING: Total connections: 6 | 'total#service.connections.tcp.count'=6;0:1;;0; 'connections.tcp.closewait.count'=0;;;0; 'connections.tcp.closed.count'=0;;;0; 'connections.tcp.closing.count'=0;;;0; 'connections.tcp.established.count'=6;;;0; 'connections.tcp.finwait1.count'=0;;;0; 'connections.tcp.finwait2.count'=0;;;0; 'connections.tcp.lastack.count'=0;;;0; 'connections.tcp.listen.count'=3;;;0; 'connections.tcp.synreceived.count'=0;;;0; 'connections.tcp.synsent.count'=0;;;0; 'connections.tcp.timewait.count'=0;;;0;
    ...    3
    ...    --critical=1
    ...    CRITICAL: Total connections: 6 | 'total#service.connections.tcp.count'=6;;0:1;0; 'connections.tcp.closewait.count'=0;;;0; 'connections.tcp.closed.count'=0;;;0; 'connections.tcp.closing.count'=0;;;0; 'connections.tcp.established.count'=6;;;0; 'connections.tcp.finwait1.count'=0;;;0; 'connections.tcp.finwait2.count'=0;;;0; 'connections.tcp.lastack.count'=0;;;0; 'connections.tcp.listen.count'=3;;;0; 'connections.tcp.synreceived.count'=0;;;0; 'connections.tcp.synsent.count'=0;;;0; 'connections.tcp.timewait.count'=0;;;0;

Tcpcon MS7000 ${tc}
    [Tags]    network    waystream    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --snmp-community=network/waystream/snmp/ms7000
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: Total connections: 6 | 'total#service.connections.tcp.count'=6;;;0; 'connections.tcp.closewait.count'=0;;;0; 'connections.tcp.closed.count'=0;;;0; 'connections.tcp.closing.count'=0;;;0; 'connections.tcp.established.count'=6;;;0; 'connections.tcp.finwait1.count'=0;;;0; 'connections.tcp.finwait2.count'=0;;;0; 'connections.tcp.lastack.count'=0;;;0; 'connections.tcp.listen.count'=3;;;0; 'connections.tcp.synreceived.count'=0;;;0; 'connections.tcp.synsent.count'=0;;;0; 'connections.tcp.timewait.count'=0;;;0;
    ...    2
    ...    --warning=1
    ...    WARNING: Total connections: 6 | 'total#service.connections.tcp.count'=6;0:1;;0; 'connections.tcp.closewait.count'=0;;;0; 'connections.tcp.closed.count'=0;;;0; 'connections.tcp.closing.count'=0;;;0; 'connections.tcp.established.count'=6;;;0; 'connections.tcp.finwait1.count'=0;;;0; 'connections.tcp.finwait2.count'=0;;;0; 'connections.tcp.lastack.count'=0;;;0; 'connections.tcp.listen.count'=3;;;0; 'connections.tcp.synreceived.count'=0;;;0; 'connections.tcp.synsent.count'=0;;;0; 'connections.tcp.timewait.count'=0;;;0;
    ...    3
    ...    --critical=1
    ...    CRITICAL: Total connections: 6 | 'total#service.connections.tcp.count'=6;;0:1;0; 'connections.tcp.closewait.count'=0;;;0; 'connections.tcp.closed.count'=0;;;0; 'connections.tcp.closing.count'=0;;;0; 'connections.tcp.established.count'=6;;;0; 'connections.tcp.finwait1.count'=0;;;0; 'connections.tcp.finwait2.count'=0;;;0; 'connections.tcp.lastack.count'=0;;;0; 'connections.tcp.listen.count'=3;;;0; 'connections.tcp.synreceived.count'=0;;;0; 'connections.tcp.synsent.count'=0;;;0; 'connections.tcp.timewait.count'=0;;;0;
