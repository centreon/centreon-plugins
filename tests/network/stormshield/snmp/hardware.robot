*** Settings ***
Documentation       Check Stormshield equipment

Resource            ${CURDIR}${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Suite Teardown      Ctn Generic Suite Teardown
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} --plugin=network::stormshield::snmp::plugin


*** Test Cases ***
hardware ${tc}
    [Tags]    network    stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/stormshield/snmp/stormshield-fake
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    --critical='temperature,.*,50'
    ...    CRITICAL: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=0C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=33C;;;0; 'hardware.temperature.count'=3;;;;
    ...    2
    ...    --threshold-overload='disk,WARNING,missing'
    ...    OK: All 3 components are ok [3/3 temperatures]. | 'cpu1#hardware.cpu.temperature.celsius'=70C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=0C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=33C;;;0; 'hardware.temperature.count'=3;;;;
    ...    3
    ...    --warning='temperature,.*,40'
    ...    WARNING: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=0C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=33C;;;0; 'hardware.temperature.count'=3;;;;
    ...    4
    ...    --warning='temperature,cpu1,60'
    ...    WARNING: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=0C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=33C;;;0; 'hardware.temperature.count'=3;;;;
    ...    5
    ...    --critical='temperature,cpu1,75'
    ...    OK: All 3 components are ok [3/3 temperatures]. | 'cpu1#hardware.cpu.temperature.celsius'=70C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=0C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=33C;;;0; 'hardware.temperature.count'=3;;;;
    ...    6
    ...    --warning='temperature,cpu1,300' --critical='temperature,cpu1,17'
    ...    CRITICAL: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=0C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=33C;;;0; 'hardware.temperature.count'=3;;;;

hardware SN910 ${tc}
    [Tags]    network    stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/stormshield/snmp/sn910
    ...    --snmp-timeout=1
    ...    ${extra_options}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:
    ...    tc
    ...    extra_options
    ...    expected_result
    ...    --
    ...    1
    ...    ${EMPTY}
    ...    OK: All 2 components are ok [2/2 temperatures]. | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.temperature.count'=2;;;;
    ...    2
    ...    --warning='temperature,.*,10'
    ...    WARNING: Temperature 'fw_2_cpu0' is '45' celsius - Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.temperature.count'=2;;;;
    ...    3
    ...    --critical='temperature,.*,10'
    ...    CRITICAL: Temperature 'fw_2_cpu0' is '45' celsius - Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.temperature.count'=2;;;;
    ...    4
    ...    --warning='temperature,cpu1,10'
    ...    WARNING: Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.temperature.count'=2;;;;
    ...    5
    ...    --critical='temperature,cpu1,10'
    ...    CRITICAL: Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.temperature.count'=2;;;;
    ...    6
    ...    --warning='temperature,cpu1,300' --critical='temperature,cpu1,17'
    ...    CRITICAL: Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.temperature.count'=2;;;;
