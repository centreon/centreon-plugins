*** Settings ***
Documentation       serial-ports mode

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${SNMPCOMMUNITY}    hardware/kvm/avocent/acs/8000/avocent8000


*** Test Cases ***
Serial Ports
    [Tags]    hardware    kvm    avocent    serial    snmp
    Remove File    /dev/shm/avocent_acs_8000_127.0.0.1_2024_serial-ports*
    ${output}    Run Avocent 8000 Plugin    "serial-ports"    --statefile-dir=/dev/shm/
    ${output}    Strip String    ${output}
    Should Be Equal As Strings
    ...    ${output}
    ...    OK: All serial ports are ok
    ...    Wrong output result for command:{\n}${output}{\n}{\n}{\n}

    ${output}    Run Avocent 8000 Plugin    "serial-ports"    --statefile-dir=/dev/shm/
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
    ...    --hostname=${HOSTNAME}
    ...    --snmp-version=${SNMPVERSION}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=${SNMPCOMMUNITY}
    ...    ${extraoptions}

    ${output}    Run    ${command}
    RETURN    ${output}
