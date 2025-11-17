*** Settings ***
Documentation       Forcepoint SD-WAN Mode DroppedPackets

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
DroppedPackets ${tc}
    [Tags]    network    forcepoint    sdwan    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=dropped-packets
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                           expected_result    --
            ...      1     ${EMPTY}                                                OK: dropped-packets-sec : buffer creation
            ...      2     ${EMPTY}                                                OK: Packets Dropped : 0.00 /s | 'dropped.packets.persecond'=0.00packets/s;;;0;
            ...      3     --warning-dropped-packets-sec=1:                        WARNING: Packets Dropped : 0.00 /s | 'dropped.packets.persecond'=0.00packets/s;1:;;0;
            ...      4     --critical-dropped-packets-sec=1:                       CRITICAL: Packets Dropped : 0.00 /s | 'dropped.packets.persecond'=0.00packets/s;;1:;0;
