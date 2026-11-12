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
    ...    CRITICAL: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;;0:50;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;0:50;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=50C;;;0; 'hardware.temperature.count'=2;;;;
    ...    2
    ...    --threshold-overload='disk,WARNING,missing'
    ...    OK: All 2 components are ok [2/2 temperatures]. | 'cpu1#hardware.cpu.temperature.celsius'=70C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=50C;;;0; 'hardware.temperature.count'=2;;;;
    ...    3
    ...    --warning='temperature,.*,40'
    ...    WARNING: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;0:40;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;0:40;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=50C;;;0; 'hardware.temperature.count'=2;;;;
    ...    4
    ...    --warning='temperature,cpu1,60'
    ...    WARNING: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;0:60;;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=50C;;;0; 'hardware.temperature.count'=2;;;;
    ...    5
    ...    --critical='temperature,cpu1,75'
    ...    OK: All 2 components are ok [2/2 temperatures]. | 'cpu1#hardware.cpu.temperature.celsius'=70C;;0:75;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=50C;;;0; 'hardware.temperature.count'=2;;;;
    ...    6
    ...    --warning='temperature,cpu1,300' --critical='temperature,cpu1,17'
    ...    CRITICAL: Temperature 'cpu1' is '70' celsius | 'cpu1#hardware.cpu.temperature.celsius'=70C;0:300;0:17;0; 'cpu2#hardware.cpu.temperature.celsius'=30C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=50C;;;0; 'hardware.temperature.count'=2;;;;

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
    ...    OK: All 3 components are ok [1/1 disks, 2/2 temperatures]. | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=2;;;;
    ...    2
    ...    --warning='temperature,.*,10'
    ...    WARNING: Temperature 'fw_2_cpu0' is '45' celsius - Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;0:10;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;0:10;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=2;;;;
    ...    3
    ...    --critical='temperature,.*,10'
    ...    CRITICAL: Temperature 'fw_2_cpu0' is '45' celsius - Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;0:10;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;0:10;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=2;;;;
    ...    4
    ...    --warning='temperature,cpu1,10'
    ...    WARNING: Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;0:10;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=2;;;;
    ...    5
    ...    --critical='temperature,cpu1,10'
    ...    CRITICAL: Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;;0:10;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=2;;;;
    ...    6
    ...    --warning='temperature,cpu1,300' --critical='temperature,cpu1,17'
    ...    CRITICAL: Temperature 'fw_2_cpu1' is '46' celsius | 'fw_2_cpu0#hardware.cpu.temperature.celsius'=45C;;;0; 'fw_2_cpu1#hardware.cpu.temperature.celsius'=46C;0:300;0:17;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=45C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=2;;;;

hardware SN510 HA without per-node tables ${tc}
    [Tags]    network    stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/stormshield/snmp/sn510-ha-sns47
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
    ...    OK: All 5 components are ok [1/1 disks, 4/4 temperatures]. | 'cpu0#hardware.cpu.temperature.celsius'=26C;;;0; 'cpu1#hardware.cpu.temperature.celsius'=26C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=27C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=27C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=26C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=4;;;;
    ...    2
    ...    --component=disk
    ...    OK: All 1 components are ok [1/1 disks]. | 'hardware.disk.count'=1;;;;
    ...    3
    ...    --warning='temperature,cpu3,25'
    ...    WARNING: Temperature 'cpu3' is '27' celsius | 'cpu0#hardware.cpu.temperature.celsius'=26C;;;0; 'cpu1#hardware.cpu.temperature.celsius'=26C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=27C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=27C;0:25;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=26C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=4;;;;
    ...    4
    ...    --filter=temperature,cpu0
    ...    OK: All 4 components are ok [1/1 disks, 3/3 temperatures]. | 'cpu1#hardware.cpu.temperature.celsius'=26C;;;0; 'cpu2#hardware.cpu.temperature.celsius'=27C;;;0; 'cpu3#hardware.cpu.temperature.celsius'=27C;;;0; 'cpu_average_temp#hardware.cpu.average.temperature.celsius'=26C;;;0; 'hardware.disk.count'=1;;;; 'hardware.temperature.count'=3;;;;

hardware SN310 HA ${tc}
    [Tags]    network    stormshield
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=hardware
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=network/stormshield/snmp/sn310-ha-sns311
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
    ...    OK: All 2 components are ok [2/2 temperatures]. | 'fw_1_cpu0#hardware.cpu.temperature.celsius'=66C;;;0; 'fw_1_cpu_average_temp#hardware.cpu.average.temperature.celsius'=66C;;;0; 'fw_2_cpu0#hardware.cpu.temperature.celsius'=67C;;;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=67C;;;0; 'hardware.temperature.count'=2;;;;
    ...    2
    ...    --critical='temperature,fw_2,60'
    ...    CRITICAL: Temperature 'fw_2_cpu0' is '67' celsius | 'fw_1_cpu0#hardware.cpu.temperature.celsius'=66C;;;0; 'fw_1_cpu_average_temp#hardware.cpu.average.temperature.celsius'=66C;;;0; 'fw_2_cpu0#hardware.cpu.temperature.celsius'=67C;;0:60;0; 'fw_2_cpu_average_temp#hardware.cpu.average.temperature.celsius'=67C;;;0; 'hardware.temperature.count'=2;;;;
