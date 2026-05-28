*** Settings ***
Documentation       Check PaloAlto system information and status.

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Start Mockoon    ${MOCKOON_JSON}
Suite Teardown      Stop Mockoon
Test Timeout        120s


*** Variables ***
${MOCKOON_JSON}     ${CURDIR}${/}mockoon-paloalto-api.json
${HOSTNAME}         127.0.0.1
${APIPORT}          3000
${CMD}              ${CENTREON_PLUGINS}
...                 --plugin=network::paloalto::api::plugin
...                 --hostname=${HOSTNAME}
...                 --port=${APIPORT}
...                 --proto=http
...                 --mode=system


*** Test Cases ***
paloalto-system ${tc}
    [Tags]    network    paloalto    api    system

    ${command}    Catenate
    ...    ${CMD}
    ...    --auth-type=api-key
    ...    --api-key=D@pAs$W@rD
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: System uptime: 8552549 seconds, certificate status: Valid, operational mode: normal, packet rate: 0 p/s, throughput: 0.00 b/s, total active sessions: 0 | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    2
    ...    --warning-uptime=:1000
    ...    WARNING: System uptime: 8552549 seconds | 'system.uptime.seconds'=8552549s;0:1000;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    3
    ...    --critical-uptime=:1000
    ...    CRITICAL: System uptime: 8552549 seconds | 'system.uptime.seconds'=8552549s;;0:1000;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    4
    ...    --warning-certificate-status='\\\%{cert_status} =~ /Valid/'
    ...    WARNING: System certificate status: Valid | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    5
    ...    --critical-certificate-status='\\\%{cert_status} =~ /Valid/'
    ...    CRITICAL: System certificate status: Valid | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    6
    ...    --warning-software-version='\\\%{sw_version} !~ /2\.0/'
    ...    WARNING: System software version: 10.1.12 | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    7
    ...    --critical-software-version='\\\%{sw_version} !~ /2\.0/'
    ...    CRITICAL: System software version: 10.1.12 | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    8
    ...    --warning-operational-mode='\\\%{operational_mode} =~ /normal/'
    ...    WARNING: System operational mode: normal | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    9
    ...    --critical-operational-mode='\\\%{operational_mode} =~ /normal/'
    ...    CRITICAL: System operational mode: normal | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    10
    ...    --warning-wildfire-mode='\\\%{wildfire_mode} =~ /disabled/i'
    ...    WARNING: System WildFire mode: Disabled | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    11
    ...    --critical-wildfire-mode='\\\%{wildfire_mode} =~ /disabled/i'
    ...    CRITICAL: System WildFire mode: Disabled | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    12
    ...    --target=001802000104
    ...    OK: System uptime: 1037126 seconds, certificate status: Valid, operational mode: normal, packet rate: 0 p/s, throughput: 0.00 b/s, total active sessions: 0 | 'system.uptime.seconds'=1037126s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    13
    ...    --warning-active-sessions=1:
    ...    WARNING: System total active sessions: 0 | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;1:;;0;
    ...    14
    ...    --critical-active-sessions=1:
    ...    CRITICAL: System total active sessions: 0 | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;1:;0;
    ...    15
    ...    --warning-packet-rate=1:
    ...    WARNING: System packet rate: 0 p/s | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;1:;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    16
    ...    --critical-packet-rate=1:
    ...    CRITICAL: System packet rate: 0 p/s | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;1:;0; 'system.sessions.throughput.bitspersecond'=0b/s;;;0; 'system.sessions.total.count'=0;;;0;
    ...    17
    ...    --warning-sessions-traffic=1:
    ...    WARNING: System throughput: 0.00 b/s | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;1:;;0; 'system.sessions.total.count'=0;;;0;
    ...    18
    ...    --critical-sessions-traffic=1:
    ...    CRITICAL: System throughput: 0.00 b/s | 'system.uptime.seconds'=8552549s;;;0; 'system.sessions.packet.rate.persecond'=0p/s;;;0; 'system.sessions.throughput.bitspersecond'=0b/s;;1:;0; 'system.sessions.total.count'=0;;;0;
