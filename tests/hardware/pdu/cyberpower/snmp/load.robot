***Settings***
Documentation       Hardware Camera Avigilon memory

Resource           ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} 
...         --plugin=hardware::pdu::cyberpower::snmp::plugin

*** Test Cases ***
load ${tc}
    [Documentation]    Hardware Camera Avigilon Memory
    [Tags]    hardware    cyberpower    load
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=load
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=hardware/pdu/cyberpower/snmp/CyberPower
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extraoptions                                                                         expected_result    --
            ...      1     --warning-phase-status='\\\%{state} =~ /low|nearOverload/i'                          OK: Device 'ATS011' bank '1' current : 1 A - phase '1' state: normal, current : 1 A, power : 219 W, voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      2     --critical-phase-status='\\\%{state} =~ /^overload/i'                                OK: Device 'ATS011' bank '1' current : 1 A - phase '1' state: normal, current : 1 A, power : 219 W, voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      4     --warning-phase-power='0'                                                            WARNING: Device 'ATS011' phase '1' power : 219 W | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;0:0;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      5     --warning-phase-voltage='0'                                                          WARNING: Device 'ATS011' phase '1' voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;0:0;;0;
            ...      6     --warning-bank-current=''                                                            OK: Device 'ATS011' bank '1' current : 1 A - phase '1' state: normal, current : 1 A, power : 219 W, voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      7     --critical-phase-current='0'                                                         CRITICAL: Device 'ATS011' phase '1' current : 1 A | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;0:0;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      8     --critical-phase-power='0'                                                           CRITICAL: Device 'ATS011' phase '1' power : 219 W | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;0:0;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      9     --critical-phase-voltage='300'                                                       OK: Device 'ATS011' bank '1' current : 1 A - phase '1' state: normal, current : 1 A, power : 219 W, voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;0:300;0;
            ...      10    --critical-bank-current=''                                                           OK: Device 'ATS011' bank '1' current : 1 A - phase '1' state: normal, current : 1 A, power : 219 W, voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      11    --warning-phase-status='\\\%{display} =~ /low|nearOverload/i'                        OK: Device 'ATS011' bank '1' current : 1 A - phase '1' state: normal, current : 1 A, power : 219 W, voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
            ...      12    --critical-phase-status='\\\%{display} =~ /^overload/i'                              OK: Device 'ATS011' bank '1' current : 1 A - phase '1' state: normal, current : 1 A, power : 219 W, voltage : 217.8 V | 'ATS011~1#bank.current.ampere'=1A;;;0; 'ATS011~1#phase.current.ampere'=1A;;;0; 'ATS011~1#phase.power.watt'=219W;;;0; 'ATS011~1#phase.voltage.volt'=217.8V;;;0;
