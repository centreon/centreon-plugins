*** Settings ***
Documentation       Juniper Mseries Netconf Services RPM

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::juniper::mseries::netconf::plugin
    ...    --mode=services-rpm
    ...    --hostname=${HOSTNAME}
    ...    --sshcli-command=get_data
    ...    --sshcli-path=${CURDIR}
    ...    --sshcli-option="-f=${CURDIR}${/}data${/}services_rpm.netconf"

*** Test Cases ***
Service Rpm ${tc}
    [Tags]    network    juniper    mseries    netconf
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:      tc    extraoptions    expected_result    --
            ...    1     --filter-name=TO-POP
            ...    OK: service RPM 'TO-POP' [type: icmp-ping] [source address 1.1.1.1] [target address 2.2.2.2] probe status: Response received - loss: 0.00 % - round trip time delay average: 2455 usec, jitter: 6004 usec, stdev: 2237 usec - positive round trip jitter delay average: 1097 usec, jitter: 4219 usec, stdev: 1501 usec - negative round trip jitter delay average: 1170 usec, jitter: 3863 usec, stdev: 1620 usec | 'services.detected.count'=1;;;0; 'TO-POP#service.rpm.probe.loss.percentage'=0.00%;;;0;100 'TO-POP#service.rpm.probe.rtt.delay.average.microseconds'=2455.00;;;0; 'TO-POP#service.rpm.probe.rtt.delay.jitter.microseconds'=6004.00;;;0; 'TO-POP#service.rpm.probe.rtt.delay.stdev.microseconds'=2237.00;;;0; 'TO-POP#service.rpm.probe.prtj.delay.average.microseconds'=1097.00;;;0; 'TO-POP#service.rpm.probe.prtj.delay.jitter.microseconds'=4219.00;;;0; 'TO-POP#service.rpm.probe.prtj.delay.stdev.microseconds'=1501.00;;;0; 'TO-POP#service.rpm.probe.nrtj.delay.average.microseconds'=1170.00;;;0; 'TO-POP#service.rpm.probe.nrtj.delay.jitter.microseconds'=3863.00;;;0; 'TO-POP#service.rpm.probe.nrtj.delay.stdev.microseconds'=1620.00;;;0;
            ...    2     --filter-type=icmp-ping
            ...    OK: service RPM 'TO-POP' [type: icmp-ping] [source address 1.1.1.1] [target address 2.2.2.2] probe status: Response received - loss: 0.00 % - round trip time delay average: 2455 usec, jitter: 6004 usec, stdev: 2237 usec - positive round trip jitter delay average: 1097 usec, jitter: 4219 usec, stdev: 1501 usec - negative round trip jitter delay average: 1170 usec, jitter: 3863 usec, stdev: 1620 usec | 'services.detected.count'=1;;;0; 'TO-POP#service.rpm.probe.loss.percentage'=0.00%;;;0;100 'TO-POP#service.rpm.probe.rtt.delay.average.microseconds'=2455.00;;;0; 'TO-POP#service.rpm.probe.rtt.delay.jitter.microseconds'=6004.00;;;0; 'TO-POP#service.rpm.probe.rtt.delay.stdev.microseconds'=2237.00;;;0; 'TO-POP#service.rpm.probe.prtj.delay.average.microseconds'=1097.00;;;0; 'TO-POP#service.rpm.probe.prtj.delay.jitter.microseconds'=4219.00;;;0; 'TO-POP#service.rpm.probe.prtj.delay.stdev.microseconds'=1501.00;;;0; 'TO-POP#service.rpm.probe.nrtj.delay.average.microseconds'=1170.00;;;0; 'TO-POP#service.rpm.probe.nrtj.delay.jitter.microseconds'=3863.00;;;0; 'TO-POP#service.rpm.probe.nrtj.delay.stdev.microseconds'=1620.00;;;0;
