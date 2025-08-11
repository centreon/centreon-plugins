*** Settings ***

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s
Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::sonus::sbc::snmp::plugin


*** Test Cases ***
dsp-stats ${tc}
    [Tags]    network    sonus
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=dsp-stats
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/sonus/sbc/snmp/slim_sonus-sbc
    ...    --snmp-timeout=1
    ...    ${extra_options}
 
    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc     extra_options                                                                               expected_result    --
            ...      1      ${EMPTY}                                                                                     OK: DSP '9' state is 'up', CPU usage: 1.00 %, active channels: 0 | '9#dsp.cpu.utilization.percentage'=1.00%;;;0;100 '9#dsp.channels.active.count'=0;;;0;
            ...      2      --warning-cpu-utilization='' --critical-cpu-utilization='0' --critical-status                CRITICAL: DSP '9' CPU usage: 1.00 % | '9#dsp.cpu.utilization.percentage'=1.00%;;0:0;0;100 '9#dsp.channels.active.count'=0;;;0;
            ...      3      --warning-status='\\\%{state} eq "up"'                                                       WARNING: DSP '9' state is 'up' | '9#dsp.cpu.utilization.percentage'=1.00%;;;0;100 '9#dsp.channels.active.count'=0;;;0;
            ...      4      --critical-status='\\\%{state} eq "up"'                                                      CRITICAL: DSP '9' state is 'up' | '9#dsp.cpu.utilization.percentage'=1.00%;;;0;100 '9#dsp.channels.active.count'=0;;;0;