*** Settings ***
Documentation       Hardware Video Appeartv Alarms

Resource            ${CURDIR}${/}..${/}..${/}..${/}..${/}..${/}resources/import.resource

Suite Setup         Ctn Generic Suite Setup
Test Timeout        120s


*** Variables ***
${CMD}      ${CENTREON_PLUGINS}
...         --plugin=hardware::devices::video::appeartv::snmp::plugin
...         --mode=alarms
...         --hostname=${HOSTNAME}
...         --snmp-port=${SNMPPORT}
...         --snmp-community=hardware/devices/video/appeartv/snmp/appeartv

*** Test Cases ***
AppearTV Alarms ${tc}
    [Documentation]    Hardware Video AppeartTV Alarms
    [Tags]    hardware    appeartv    alarms
    ${command}    Catenate
    ...    ${CMD}
    ...    ${extraoptions}

    Ctn Run Command And Check Result As Strings    ${command}    ${expected_result}    ${tc}

    Examples:        tc    extraoptions                                                                  expected_result    --
            ...      1     ${EMPTY}                                                                      WARNING: 1 problem(s) detected | 'alerts'=1;;;0;
            ...      2     --warning-status='\\\%{severity} =~ /minor/i'                                 WARNING: 1 problem(s) detected | 'alerts'=1;;;0;
            ...      3     --critical-status='\\\%{severity} =~ /critical|major|minor/i'                 CRITICAL: 1 problem(s) detected | 'alerts'=1;;;0;
            ...      4     --filter-msg='Error'                                                          OK: 0 problem(s) detected | 'alerts'=0;;;0;
            ...      5     --filter-msg='Disconnected'                                                   WARNING: 1 problem(s) detected | 'alerts'=1;;;0;
            ...      6     --filter-msg='Disconnected' --critical-status='\\\%{severity} =~ /minor/i'    CRITICAL: 1 problem(s) detected | 'alerts'=1;;;0;
            ...      7     --memory    WARNING: 1 problem(s) detected | 'alerts'=1;;;0;
            ...      8     --memory    OK: 0 problem(s) detected | 'alerts'=0;;;0;
