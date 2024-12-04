***Settings***
Documentation       Hardware Camera Avigilon memory

Resource           ${CURDIR}${/}..${/}..${/}..${/}..${/}resources/import.resource

Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS} 
...         --plugin=hardware::pdu::cyberpower::snmp::plugin

*** Test Cases ***
outlets ${tc}
    [Documentation]    Hardware Camera Avigilon Memory
    [Tags]    hardware    cyberpower    outlets
    ${command}    Catenate
    ...    ${CMD}
    ...    --mode=outlets
    ...    --hostname=${HOSTNAME}
    ...    --snmp-port=${SNMPPORT}
    ...    --snmp-community=hardware/pdu/cyberpower/snmp/CyberPower
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}

    Examples:        tc    extraoptions                                      expected_result    --
            ...      1     --unknown-status='\\\%{state} =~ /on/'            UNKNOWN: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]
            ...      2     --unknown-status                                  OK: Device 'ATS011' outlets are ok
            ...      3     --warning-status='\\\%{state} =~ /on/'            WARNING: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]
            ...      4     --critical-status='\\\%{state} =~ /on/'           CRITICAL: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]
            ...      5     --warning-current=''                              OK: Device 'ATS011' outlets are ok
            ...      6     --critical-current=''                             OK: Device 'ATS011' outlets are ok
            ...      7     --unknown-status='\\\%{phase} =~ /-/'             UNKNOWN: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]
            ...      8     --unknown-status='\\\%{bank} =~ /1/'              UNKNOWN: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]
            ...      9     --critical-status='\\\%{phase} =~ /-/'            CRITICAL: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]  
            ...      10    --critical-status='\\\%{bank} =~ /1/'             CRITICAL: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]
            ...      11    --critical-status='\\\%{display} =~ /off/'        OK: Device 'ATS011' outlets are ok
            ...      12    --warning-status='\\\%{bank} =~ /1/'              WARNING: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]
            ...      13    --warning-status='\\\%{display} =~ /off/'         OK: Device 'ATS011' outlets are ok
            ...      14    --warning-status='\\\%{phase} =~ /-/'             WARNING: Device 'ATS011' outlet 'Outlet1 bank 1' state: 'on' [phase: -] - outlet 'Outlet10 bank 1' state: 'on' [phase: -] - outlet 'Outlet2 bank 1' state: 'on' [phase: -] - outlet 'Outlet3 bank 1' state: 'on' [phase: -] - outlet 'Outlet4 bank 1' state: 'on' [phase: -] - outlet 'Outlet5 bank 1' state: 'on' [phase: -] - outlet 'Outlet6 bank 1' state: 'on' [phase: -] - outlet 'Outlet7 bank 1' state: 'on' [phase: -] - outlet 'Outlet8 bank 1' state: 'on' [phase: -] - outlet 'Outlet9 bank 1' state: 'on' [phase: -]

