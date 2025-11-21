*** Settings ***
Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::f5::bigip::snmp::plugin


*** Test Cases ***
trunks ${tc}
    [Tags]    network
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=trunks
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/f5/bigip/snmp/slim-f5-bigip
    ...    ${extra_options}

    Ctn Verify Command Without Connector Output    ${command}    ${expected_result}

    Examples:        tc    extra_options                                                           expected_result    --
            ...      1     ${EMPTY}                                                                OK: Trunk 'Anonymized 234' status is 'up', traffic in: Buffer creation, traffic out: Buffer creation, packets in error: Buffer creation, packets out error: Buffer creation, packets in drop: Buffer creation, packets out drop: Buffer creation
            ...      2     --filter-name='Anonymized 234'                                          OK: Trunk 'Anonymized 234' status is 'up', traffic in: Buffer creation, traffic out: Buffer creation, packets in error: Buffer creation, packets out error: Buffer creation, packets in drop: Buffer creation, packets out drop: Buffer creation
            ...      3     --warning-status='\\\%{status} eq "up"'                                 WARNING: Trunk 'Anonymized 234' status is 'up' | 'Anonymized 234#trunk.traffic.in.bitspersecond'=0.00b/s;;;0;20000000000 'Anonymized 234#trunk.traffic.out.bitspersecond'=0.00b/s;;;0;20000000000 'Anonymized 234#trunk.packets.in.error.percentage'=0.00%;;;0;100
            ...      4     --critical-status='\\\%{status} eq "up"'                                CRITICAL: Trunk 'Anonymized 234' status is 'up' | 'Anonymized 234#trunk.traffic.in.bitspersecond'=0.00b/s;;;0;20000000000 'Anonymized 234#trunk.traffic.out.bitspersecond'=0.00b/s;;;0;20000000000 'Anonymized 234#trunk.packets.in.error.percentage'=0.00%;;;0;100
            ...      5     --unknown-status='\\\%{status} eq "up"'                                 UNKNOWN: Trunk 'Anonymized 234' status is 'up' | 'Anonymized 234#trunk.traffic.in.bitspersecond'=0.00b/s;;;0;20000000000 'Anonymized 234#trunk.traffic.out.bitspersecond'=0.00b/s;;;0;20000000000 'Anonymized 234#trunk.packets.in.error.percentage'=0.00%;;;0;100
            ...      6     --warning-packets-error-in=50 --critical-packets-error-in=100           OK: Trunk 'Anonymized 234' status is 'up', traffic in: 0.00b/s (0.00%), traffic out: 0.00b/s (0.00%), packets in error: 0.00%, packets out error: 0.00%,
