*** Settings ***
Documentation       Forcepoint SD-WAN Mode RejectedPackets

Resource            ${CURDIR}${/}../..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::forcepoint::sdwan::snmp::plugin


*** Test Cases ***
RejectedPackets ${tc}
    [Tags]    network    forcepoint    sdwan    snmp
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=rejected-packets
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/forcepoint/sdwan/snmp/forcepoint
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extra_options                                           expected_result    --
            ...      1     ${EMPTY}                                                OK: rejected-packets-sec : buffer creation
            ...      2     ${EMPTY}                                                OK: Packets Rejected : 0.00 /s | 'rejected.packets.persecond'=0.00packets/s;;;0;
            ...      3     --warning-rejected-packets-sec=1:                       WARNING: Packets Rejected : 0.00 /s | 'rejected.packets.persecond'=0.00packets/s;1:;;0;
            ...      4     --critical-rejected-packets-sec=1:                      CRITICAL: Packets Rejected : 0.00 /s | 'rejected.packets.persecond'=0.00packets/s;;1:;0;
