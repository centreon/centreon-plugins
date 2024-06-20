*** Settings ***
Documentation       hardware::kvm::avocent::acs::8000::snmp::plugin

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${HOSTADDRESS}      127.0.0.1
${SNMPPORT}         2024
${SNMPVERSION}      2c
${SNMPCOMMUNITY}    hardware/kvm/avocent/acs/8000/avocent8000


*** Test Cases ***
Cpu-Detailed
    [Documentation]    cpu-detailed mode
    [Tags]    hardware    kvm    avocent    cpu    snmp
    Remove File    /dev/shm/snmpstandard_127.0.0.1_2024_cpu-detailed*
    ${output}    Run Avocent 8000 Plugin    "cpu-detailed"    --statefile-dir=/tmp/cache/
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: CPU Usage: user : Buffer creation, nice : Buffer creation, system : Buffer creation, idle : Buffer creation, wait : Buffer creation, kernel : Buffer creation, interrupt : Buffer creation, softirq : Buffer creation, steal : Buffer creation, guest : Buffer creation, guestnice : Buffer creation
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

    ${output}    Run Avocent 8000 Plugin    "cpu-detailed"    --statefile-dir=/tmp/cache/
    ${output}    Strip String    ${output}
    Remove File    /dev/shm/snmpstandard_127.0.0.1_2024_cpu-detailed*
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: CPU Usage: user : counter not moved, nice : counter not moved, system : counter not moved, idle : counter not moved, wait : counter not moved, kernel : counter not moved, interrupt : counter not moved, softirq : counter not moved, steal : counter not moved, guest : counter not moved, guestnice : counter not moved
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

Hardware
    [Documentation]    hardware mode
    [Tags]    hardware    kvm    avocent    hardware-mode    snmp
    ${output}    Run Avocent 8000 Plugin    "hardware"    ""

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: All 2 components are ok [2/2 psus]. | 'hardware.psu.count'=2;;;;
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

Load
    [Documentation]    load mode
    [Tags]    hardware    kvm    avocent    load    snmp
    ${output}    Run Avocent 8000 Plugin    "load"    ""

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: Load average: 0.04, 0.10, 0.15 | 'load1'=0.04;;;0; 'load5'=0.10;;;0; 'load15'=0.15;;;0;
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

Memory
    [Documentation]    memory mode
    [Tags]    hardware    kvm    avocent    memory    snmp
    ${output}    Run Avocent 8000 Plugin    "memory"    ""

    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: Ram Total: 1.92 GB Used (-buffers/cache): 626.18 MB (31.79%) Free: 1.31 GB (68.21%), Buffer: 2.04 MB, Cached: 723.54 MB, Shared: 26.09 MB | 'used'=656592896B;;;0;2065698816 'free'=1409105920B;;;0;2065698816 'used_prct'=31.79%;;;0;100 'buffer'=2134016B;;;0; 'cached'=758689792B;;;0; 'shared'=27357184B;;;0;
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

Serial Ports
    [Documentation]    serial-ports mode
    [Tags]    hardware    kvm    avocent    serial    snmp
    Remove File    /dev/shm/avocent_acs_8000_127.0.0.1_2024_serial-ports*
    ${output}    Run Avocent 8000 Plugin    "serial-ports"    --statefile-dir=/tmp/cache/
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: All serial ports are ok
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

    ${output}    Run Avocent 8000 Plugin    "serial-ports"    --statefile-dir=/tmp/cache/
    ${output}    Strip String    ${output}
    Remove File    /dev/shm/avocent_acs_8000_127.0.0.1_2024_serial-ports*
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: All serial ports are ok | 'ttyS1#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS1#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS10#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS10#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS11#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS11#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS12#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS12#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS13#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS13#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS14#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS14#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS15#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS15#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS16#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS16#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS2#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS2#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS3#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS3#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS4#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS4#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS5#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS5#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS6#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS6#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS7#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS7#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS8#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS8#serialport.traffic.out.bitspersecond'=0b/s;;;0; 'ttyS9#serialport.traffic.in.bitspersecond'=0b/s;;;0; 'ttyS9#serialport.traffic.out.bitspersecond'=0b/s;;;0;
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}


*** Keywords ***
Run Avocent 8000 Plugin
    [Arguments]    ${mode}    ${extraoptions}
    ${command}    Catenate
    ...    ${CENTREON_PLUGINS}
    ...    --plugin=hardware::kvm::avocent::acs::8000::snmp::plugin
    ...    --mode=${mode}
    ...    --hostname=${HOSTADDRESS}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${SNMPCOMMUNITY}
    ...    ${extraoptions}

    ${output}    Run    ${command}
    RETURN    ${output}
