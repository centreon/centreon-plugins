*** Settings ***
Documentation       Network Fortinet Fortigate SNMP plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}                                          ${CENTREON_PLUGINS} --plugin=network::fortinet::fortigate::snmp::plugin

# Test simple usage of the linkmonitor mode
&{fortinet_fortigate_linkmonitor_test1}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with filter-id option set to 3
&{fortinet_fortigate_linkmonitor_test2}
...                                             filterid=3
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead | 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with filter-name option set to MonitorWAN1
&{fortinet_fortigate_linkmonitor_test3}
...                                             filterid=
...                                             filtername='MonitorWAN1'
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=OK: Link monitor 'MonitorWAN1' [vdom: root] [id: 1] state: alive, latency: 39.739ms, jitter: 0.096ms, packet loss: 0.000% | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0;

# Test linkmonitor mode with filter-vdom option set to 'root'
&{fortinet_fortigate_linkmonitor_test4}
...                                             filterid=
...                                             filtername=
...                                             filtervdom='root'
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with custom-perf-data-instances option set to '%(name) %(id)'
&{fortinet_fortigate_linkmonitor_test5}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances='%(name) %(id)'
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead | 'MonitorWAN1~1#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~1#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~1#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~2#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~2#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~2#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~3#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~3#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~3#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with unknown-status option set to '%{state} eq "alive"'
&{fortinet_fortigate_linkmonitor_test6}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus='\%{state} eq "alive"'
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead UNKNOWN: Link monitor 'MonitorWAN1' [vdom: root] [id: 1] state: alive - Link monitor 'MonitorWAN2' [vdom: root] [id: 2] state: alive | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with warning-status option set to '%{state} eq "alive"'
&{fortinet_fortigate_linkmonitor_test7}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus='\%{state} eq "alive"'
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead WARNING: Link monitor 'MonitorWAN1' [vdom: root] [id: 1] state: alive - Link monitor 'MonitorWAN2' [vdom: root] [id: 2] state: alive | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with critical-status option set to '%{state} eq "alive"'
&{fortinet_fortigate_linkmonitor_test8}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus='\%{state} eq "alive"'
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN1' [vdom: root] [id: 1] state: alive - Link monitor 'MonitorWAN2' [vdom: root] [id: 2] state: alive | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with warning-latency option set to 40
&{fortinet_fortigate_linkmonitor_test9}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=40
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead WARNING: Link monitor 'MonitorWAN2' [vdom: root] [id: 2] latency: 46.446ms | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;0:40;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;0:40;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;0:40;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with critical-latency option set to 40
&{fortinet_fortigate_linkmonitor_test10}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=40
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN2' [vdom: root] [id: 2] latency: 46.446ms - Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;0:40;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;0:40;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;0:40;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with warning-jitter option set to 1
&{fortinet_fortigate_linkmonitor_test11}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=1
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead WARNING: Link monitor 'MonitorWAN2' [vdom: root] [id: 2] jitter: 1.868ms | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;0:1;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;0:1;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;0:1;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with critical-jitter option set to 1
&{fortinet_fortigate_linkmonitor_test12}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=1
...                                             warningpacketloss=
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN2' [vdom: root] [id: 2] jitter: 1.868ms - Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;0:1;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;0:1;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;0:1;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;;0;

# Test linkmonitor mode with warning-packetloss option set to 0.5
&{fortinet_fortigate_linkmonitor_test13}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=0.5
...                                             criticalpacketloss=
...                                             result=CRITICAL: Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead, packet loss: 100.000% WARNING: Link monitor 'MonitorWAN2' [vdom: root] [id: 2] packet loss: 1.000% | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;0:0.5;;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;0:0.5;;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;0:0.5;;0;

# Test linkmonitor mode with critical-packetloss option set to 0.5
&{fortinet_fortigate_linkmonitor_test14}
...                                             filterid=
...                                             filtername=
...                                             filtervdom=
...                                             customperfdatainstances=
...                                             unknownstatus=
...                                             warningstatus=
...                                             criticalstatus=
...                                             warninglatency=
...                                             criticallatency=
...                                             warningjitter=
...                                             criticaljitter=
...                                             warningpacketloss=
...                                             criticalpacketloss=0.5
...                                             result=CRITICAL: Link monitor 'MonitorWAN2' [vdom: root] [id: 2] packet loss: 1.000% - Link monitor 'MonitorWAN3' [vdom: root] [id: 3] state: dead, packet loss: 100.000% | 'MonitorWAN1~root#linkmonitor.latency.milliseconds'=39.739;;;0; 'MonitorWAN1~root#linkmonitor.jitter.milliseconds'=0.096;;;0; 'MonitorWAN1~root#linkmonitor.packet.loss.percentage'=0;;0:0.5;0; 'MonitorWAN2~root#linkmonitor.latency.milliseconds'=46.446;;;0; 'MonitorWAN2~root#linkmonitor.jitter.milliseconds'=1.868;;;0; 'MonitorWAN2~root#linkmonitor.packet.loss.percentage'=1;;0:0.5;0; 'MonitorWAN3~root#linkmonitor.latency.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.jitter.milliseconds'=0.000;;;0; 'MonitorWAN3~root#linkmonitor.packet.loss.percentage'=100;;0:0.5;0;

@{fortinet_fortigate_linkmonitor_tests}
...                                             &{fortinet_fortigate_linkmonitor_test1}
...                                             &{fortinet_fortigate_linkmonitor_test2}
...                                             &{fortinet_fortigate_linkmonitor_test3}
...                                             &{fortinet_fortigate_linkmonitor_test4}
...                                             &{fortinet_fortigate_linkmonitor_test5}
...                                             &{fortinet_fortigate_linkmonitor_test6}
...                                             &{fortinet_fortigate_linkmonitor_test7}
...                                             &{fortinet_fortigate_linkmonitor_test8}
...                                             &{fortinet_fortigate_linkmonitor_test9}
...                                             &{fortinet_fortigate_linkmonitor_test10}
...                                             &{fortinet_fortigate_linkmonitor_test11}
...                                             &{fortinet_fortigate_linkmonitor_test12}
...                                             &{fortinet_fortigate_linkmonitor_test13}
...                                             &{fortinet_fortigate_linkmonitor_test14}

# Test simple usage of the list-linkmonitors mode
&{fortinet_fortigate_listlinkmonitors_test1}
...                                             filterstate=
...                                             filtername=
...                                             filtervdom=
...                                             result=List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]\n[Name = MonitorWAN2] [Vdom = root] [State = alive]\n[Name = MonitorWAN3] [Vdom = root] [State = dead]

# Test list-linkmonitors mode with filter-name option set to MonitorWAN1
&{fortinet_fortigate_listlinkmonitors_test2}
...                                             filterstate=
...                                             filtername='MonitorWAN1'
...                                             filtervdom=
...                                             result=List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]

# Test list-linkmonitors mode with filter-state option set to alive
&{fortinet_fortigate_listlinkmonitors_test3}
...                                             filterstate='alive'
...                                             filtername=
...                                             filtervdom=
...                                             result=List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]\n[Name = MonitorWAN2] [Vdom = root] [State = alive]

# Test list-linkmonitors mode with filter-vdom option set to root
&{fortinet_fortigate_listlinkmonitors_test4}
...                                             filterstate=
...                                             filtername=
...                                             filtervdom='root'
...                                             result=List link monitors: \n[Name = MonitorWAN1] [Vdom = root] [State = alive]\n[Name = MonitorWAN2] [Vdom = root] [State = alive]\n[Name = MonitorWAN3] [Vdom = root] [State = dead]

@{fortinet_fortigate_listlinkmonitors_tests}
...                                             &{fortinet_fortigate_listlinkmonitors_test1}
...                                             &{fortinet_fortigate_listlinkmonitors_test2}
...                                             &{fortinet_fortigate_listlinkmonitors_test3}
...                                             &{fortinet_fortigate_listlinkmonitors_test4}


*** Test Cases ***
Network Fortinet Fortigate SNMP link monitor
    [Documentation]    Network Fortinet Fortigate SNMP link-monitor
    [Tags]    network    fortinet    fortigate    snmp
    FOR    ${fortinet_fortigate_linkmonitor_test}    IN    @{fortinet_fortigate_linkmonitor_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=link-monitor
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2c
        ...    --snmp-port=2024
        ...    --snmp-community=network/fortinet/fortigate/snmp/linkmonitor
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.filterid}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-id=${fortinet_fortigate_linkmonitor_test.filterid}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.filtername}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-name=${fortinet_fortigate_linkmonitor_test.filtername}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.filtervdom}
        IF    ${length} > 0
            ${command}    Catenate    ${command}    --filter-vdom=${fortinet_fortigate_linkmonitor_test.filtervdom}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.customperfdatainstances}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --custom-perfdata-instances=${fortinet_fortigate_linkmonitor_test.customperfdatainstances}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.unknownstatus}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --unknown-status=${fortinet_fortigate_linkmonitor_test.unknownstatus}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.warningstatus}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-status=${fortinet_fortigate_linkmonitor_test.warningstatus}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.criticalstatus}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-status=${fortinet_fortigate_linkmonitor_test.criticalstatus}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.warninglatency}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-latency=${fortinet_fortigate_linkmonitor_test.warninglatency}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.criticallatency}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-latency=${fortinet_fortigate_linkmonitor_test.criticallatency}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.warningjitter}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-jitter=${fortinet_fortigate_linkmonitor_test.warningjitter}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.criticaljitter}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-jitter=${fortinet_fortigate_linkmonitor_test.criticaljitter}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.warningpacketloss}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --warning-packet-loss=${fortinet_fortigate_linkmonitor_test.warningpacketloss}
        END
        ${length}    Get Length    ${fortinet_fortigate_linkmonitor_test.criticalpacketloss}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --critical-packet-loss=${fortinet_fortigate_linkmonitor_test.criticalpacketloss}
        END
        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${fortinet_fortigate_linkmonitor_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${fortinet_fortigate_linkmonitor_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END

Network Fortinet Fortigate SNMP list link monitor
    [Documentation]    Network Fortinet Fortigate SNMP list-linkmonitors
    [Tags]    network    fortinet    fortigate    snmp
    FOR    ${fortinet_fortigate_listlinkmonitors_test}    IN    @{fortinet_fortigate_listlinkmonitors_tests}
        ${command}    Catenate
        ...    ${CMD}
        ...    --mode=list-link-monitors
        ...    --hostname=127.0.0.1
        ...    --snmp-version=2c
        ...    --snmp-port=2024
        ...    --snmp-community=network/fortinet/fortigate/snmp/linkmonitor
        ${length}    Get Length    ${fortinet_fortigate_listlinkmonitors_test.filterstate}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --filter-state=${fortinet_fortigate_listlinkmonitors_test.filterstate}
        END
        ${length}    Get Length    ${fortinet_fortigate_listlinkmonitors_test.filtername}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --filter-name=${fortinet_fortigate_listlinkmonitors_test.filtername}
        END
        ${length}    Get Length    ${fortinet_fortigate_listlinkmonitors_test.filtervdom}
        IF    ${length} > 0
            ${command}    Catenate
            ...    ${command}
            ...    --filter-vdom=${fortinet_fortigate_listlinkmonitors_test.filtervdom}
        END
        ${output}    Run    ${command}
        Log To Console    .    no_newline=true
        ${output}    Strip String    ${output}
        Should Be Equal As Strings
        ...    ${output}
        ...    ${fortinet_fortigate_listlinkmonitors_test.result}
        ...    Wrong result output for:${\n}Command: ${\n}${command}${\n}${\n}Expected output: ${\n}${fortinet_fortigate_listlinkmonitors_test.result}${\n}${\n}Obtained output:${\n}${output}${\n}${\n}${\n}
        ...    values=False
    END
