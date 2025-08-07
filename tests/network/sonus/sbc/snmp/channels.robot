*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::sonus::sbc::snmp::plugin


*** Test Cases ***
channels ${tc}
    [Tags]    network    sonus
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=channels
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/sonus/sbc/snmp/slim_sonus-sbc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc     extra_options                                                                          expected_result    --
            ...      1      ${EMPTY}                                                                               OK: All channels are ok | 'channels.total.count'=4;;;0; 'channels.outofservice.count'=0;;;0; 'channels.idle.count'=4;;;0; 'channels.pending.count'=0;;;0; 'channels.waiting_for_route.count'=0;;;0; 'channels.action_list.count'=0;;;0; 'channels.waiting_for_digits.count'=0;;;0; 'channels.remote_setup.count'=0;;;0; 'channels.peer_setup.count'=0;;;0; 'channels.alerting.count'=0;;;0; 'channels.inband_info.count'=0;;;0; 'channels.connected.count'=0;;;0; 'channels.tone_generation.count'=0;;;0; 'channels.releasing.count'=0;;;0; 'channels.aborting.count'=0;;;0; 'channels.resetting.count'=0;;;0; 'channels.up.count'=0;;;0; 'channels.down.count'=0;;;0; 'shelf1~slot0~port1~channel1#channel.lifetime.seconds'=43316s;;;0; 'shelf1~slot0~port1~channel2#channel.lifetime.seconds'=42338s;;;0; 'shelf1~slot1~port1~channel1#channel.lifetime.seconds'=515930s;;;0; 'shelf1~slot1~port2~channel1#channel.lifetime.seconds'=138887s;;;0;
            ...      6      --filter-channel-id='1/1/1/1'                                                          OK: | 'channels.total.count'=0;;;0; 'channels.outofservice.count'=0;;;0; 'channels.idle.count'=0;;;0; 'channels.pending.count'=0;;;0; 'channels.waiting_for_route.count'=0;;;0; 'channels.action_list.count'=0;;;0; 'channels.waiting_for_digits.count'=0;;;0; 'channels.remote_setup.count'=0;;;0; 'channels.peer_setup.count'=0;;;0; 'channels.alerting.count'=0;;;0; 'channels.inband_info.count'=0;;;0; 'channels.connected.count'=0;;;0; 'channels.tone_generation.count'=0;;;0; 'channels.releasing.count'=0;;;0; 'channels.aborting.count'=0;;;0; 'channels.resetting.count'=0;;;0; 'channels.up.count'=0;;;0; 'channels.down.count'=0;;;0;   
            ...      7      --warning-status='\\\%{opstatus} eq "idle"'                                            WARNING: channel '1/0/1/1' oper status: idle - channel '1/0/1/2' oper status: idle - channel '1/1/1/1' oper status: idle - channel '1/1/2/1' oper status: idle | 'channels.total.count'=4;;;0; 'channels.outofservice.count'=0;;;0; 'channels.idle.count'=4;;;0; 'channels.pending.count'=0;;;0; 'channels.waiting_for_route.count'=0;;;0; 'channels.action_list.count'=0;;;0; 'channels.waiting_for_digits.count'=0;;;0; 'channels.remote_setup.count'=0;;;0; 'channels.peer_setup.count'=0;;;0; 'channels.alerting.count'=0;;;0; 'channels.inband_info.count'=0;;;0; 'channels.connected.count'=0;;;0; 'channels.tone_generation.count'=0;;;0; 'channels.releasing.count'=0;;;0; 'channels.aborting.count'=0;;;0; 'channels.resetting.count'=0;;;0; 'channels.up.count'=0;;;0; 'channels.down.count'=0;;;0; 'shelf1~slot0~port1~channel1#channel.lifetime.seconds'=43316s;;;0; 'shelf1~slot0~port1~channel2#channel.lifetime.seconds'=42338s;;;0; 'shelf1~slot1~port1~channel1#channel.lifetime.seconds'=515930s;;;0; 'shelf1~slot1~port2~channel1#channel.lifetime.seconds'=138887s;;;0;
            ...      8      --critical-status='\\\%{opstatus} eq "idle"'                                           CRITICAL: channel '1/0/1/1' oper status: idle - channel '1/0/1/2' oper status: idle - channel '1/1/1/1' oper status: idle - channel '1/1/2/1' oper status: idle | 'channels.total.count'=4;;;0; 'channels.outofservice.count'=0;;;0; 'channels.idle.count'=4;;;0; 'channels.pending.count'=0;;;0; 'channels.waiting_for_route.count'=0;;;0; 'channels.action_list.count'=0;;;0; 'channels.waiting_for_digits.count'=0;;;0; 'channels.remote_setup.count'=0;;;0; 'channels.peer_setup.count'=0;;;0; 'channels.alerting.count'=0;;;0; 'channels.inband_info.count'=0;;;0; 'channels.connected.count'=0;;;0; 'channels.tone_generation.count'=0;;;0; 'channels.releasing.count'=0;;;0; 'channels.aborting.count'=0;;;0; 'channels.resetting.count'=0;;;0; 'channels.up.count'=0;;;0; 'channels.down.count'=0;;;0; 'shelf1~slot0~port1~channel1#channel.lifetime.seconds'=43316s;;;0; 'shelf1~slot0~port1~channel2#channel.lifetime.seconds'=42338s;;;0; 'shelf1~slot1~port1~channel1#channel.lifetime.seconds'=515930s;;;0; 'shelf1~slot1~port2~channel1#channel.lifetime.seconds'=138887s;;;0;
            ...      9      --warning-channels-total=1 --critical-channels-total=1 --filter-counters='total'       CRITICAL: number of channels total: 4 | 'channels.total.count'=4;0:1;0:1;0;